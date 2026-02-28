import Foundation

struct DNSFlushResult: Equatable {
    let isSuccess: Bool
    let message: String
}

struct DNSFlushService {
    private let commandRunner: CommandRunning

    init(commandRunner: CommandRunning = ProcessCommandRunner()) {
        self.commandRunner = commandRunner
    }

    func flushDNSCache() -> DNSFlushResult {
        do {
            try commandRunner.run(executablePath: "/usr/bin/dscacheutil", arguments: ["-flushcache"])
            try commandRunner.run(executablePath: "/usr/bin/killall", arguments: ["-HUP", "mDNSResponder"])
            return DNSFlushResult(isSuccess: true, message: LocalizationCatalog.localized("utility.dns.flush.success"))
        } catch {
            return DNSFlushResult(isSuccess: false, message: LocalizationCatalog.localized("utility.dns.flush.failure"))
        }
    }
}
