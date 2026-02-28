import Foundation

protocol HardwarePortMappingProviding: AnyObject {
    func currentMap() -> [String: String]
    func refreshAsyncIfNeeded()
}

final class DefaultHardwarePortMappingProvider: HardwarePortMappingProviding, @unchecked Sendable {
    typealias AsyncExecutor = (@escaping @Sendable () -> Void) -> Void

    private let refreshInterval: TimeInterval
    private let now: () -> Date
    private let loadOutput: @Sendable () -> String?
    private let executeAsync: AsyncExecutor

    private let lock = NSLock()
    private var map: [String: String] = [:]
    private var lastRefreshDate: Date?
    private var refreshInFlight = false

    init(
        refreshInterval: TimeInterval = 300,
        now: @escaping () -> Date = Date.init,
        loadOutput: @escaping @Sendable () -> String? = DefaultHardwarePortMappingProvider.loadHardwarePortOutput,
        executeAsync: AsyncExecutor? = nil
    ) {
        self.refreshInterval = refreshInterval
        self.now = now
        self.loadOutput = loadOutput

        if let executeAsync {
            self.executeAsync = executeAsync
        } else {
            let queue = DispatchQueue(label: "com.nibble.hardware-port-map", qos: .utility)
            self.executeAsync = { work in
                queue.async(execute: work)
            }
        }
    }

    func currentMap() -> [String: String] {
        lock.lock()
        defer { lock.unlock() }
        return map
    }

    func refreshAsyncIfNeeded() {
        lock.lock()
        let shouldRefresh = shouldRefreshLocked(now: now())
        if shouldRefresh {
            refreshInFlight = true
        }
        lock.unlock()

        guard shouldRefresh else {
            return
        }

        executeAsync { [weak self] in
            self?.refreshNow()
        }
    }

    private func refreshNow() {
        let output = loadOutput()
        let parsedMap = output.map(HardwarePortMapper.parse)
        let finishedAt = now()

        lock.lock()
        if let parsedMap {
            map = parsedMap
        }
        lastRefreshDate = finishedAt
        refreshInFlight = false
        lock.unlock()
    }

    private func shouldRefreshLocked(now: Date) -> Bool {
        guard !refreshInFlight else {
            return false
        }

        guard let lastRefreshDate else {
            return true
        }

        return now.timeIntervalSince(lastRefreshDate) >= refreshInterval
    }

    private static func loadHardwarePortOutput() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-listallhardwareports"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            guard task.terminationStatus == 0 else {
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
