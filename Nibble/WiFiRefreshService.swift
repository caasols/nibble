import Foundation

enum WiFiRefreshResult: Equatable {
    case success
    case cooldown(remainingSeconds: Int)
    case failure
}

final class WiFiRefreshService {
    private let commandRunner: CommandRunning
    private let cooldown: TimeInterval
    private let now: () -> Date
    private var lastRefreshAt: Date?

    init(
        commandRunner: CommandRunning = ProcessCommandRunner(),
        cooldown: TimeInterval = 120,
        now: @escaping () -> Date = Date.init
    ) {
        self.commandRunner = commandRunner
        self.cooldown = cooldown
        self.now = now
    }

    func refreshWiFi() -> WiFiRefreshResult {
        let currentDate = now()
        if let lastRefreshAt {
            let elapsed = currentDate.timeIntervalSince(lastRefreshAt)
            if elapsed < cooldown {
                let remaining = Int((cooldown - elapsed).rounded(.up))
                return .cooldown(remainingSeconds: remaining)
            }
        }

        do {
            let output = try commandRunner.runAndCaptureOutput(
                executablePath: "/usr/sbin/networksetup",
                arguments: ["-listallhardwareports"]
            )
            guard let wifiDevice = Self.wiFiDeviceName(from: output) else {
                return .failure
            }

            try commandRunner.run(
                executablePath: "/usr/sbin/networksetup",
                arguments: ["-setairportpower", wifiDevice, "off"]
            )
            try commandRunner.run(
                executablePath: "/usr/sbin/networksetup",
                arguments: ["-setairportpower", wifiDevice, "on"]
            )

            lastRefreshAt = currentDate
            return .success
        } catch {
            return .failure
        }
    }

    private static func wiFiDeviceName(from output: String) -> String? {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
        for index in lines.indices {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("Hardware Port:") else {
                continue
            }

            let portName = line.replacingOccurrences(of: "Hardware Port:", with: "").trimmingCharacters(in: .whitespaces)
            guard portName == "Wi-Fi" else {
                continue
            }

            var cursor = lines.index(after: index)
            while cursor < lines.endIndex {
                let candidate = lines[cursor].trimmingCharacters(in: .whitespaces)
                if candidate.hasPrefix("Hardware Port:") {
                    break
                }

                if candidate.hasPrefix("Device:") {
                    return candidate.replacingOccurrences(of: "Device:", with: "").trimmingCharacters(in: .whitespaces)
                }

                cursor = lines.index(after: cursor)
            }
        }

        return nil
    }
}
