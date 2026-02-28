import Foundation
import Testing
@testable import Nibble

struct WiFiRefreshServiceTests {
    @Test func togglesWiFiOffThenOnForDetectedDevice() {
        let runner = RecordingWiFiRunner()
        runner.hardwarePortOutput = """
        Hardware Port: Wi-Fi
        Device: en0
        Ethernet Address: 00:11:22:33:44:55
        """

        let service = WiFiRefreshService(commandRunner: runner, now: { Date(timeIntervalSince1970: 100) })
        let result = service.refreshWiFi()

        #expect(result == .success)
        #expect(runner.executedCommands == [
            ["/usr/sbin/networksetup", "-listallhardwareports"],
            ["/usr/sbin/networksetup", "-setairportpower", "en0", "off"],
            ["/usr/sbin/networksetup", "-setairportpower", "en0", "on"]
        ])
    }

    @Test func rejectsRequestWithinCooldownWindow() {
        let runner = RecordingWiFiRunner()
        runner.hardwarePortOutput = """
        Hardware Port: Wi-Fi
        Device: en0
        """

        let now = MutableNow(date: Date(timeIntervalSince1970: 100))
        let service = WiFiRefreshService(commandRunner: runner, cooldown: 120, now: now.current)

        #expect(service.refreshWiFi() == .success)

        now.date = Date(timeIntervalSince1970: 150)
        let secondAttempt = service.refreshWiFi()

        if case let .cooldown(remainingSeconds) = secondAttempt {
            #expect(remainingSeconds == 70)
        } else {
            Issue.record("Expected cooldown result")
        }
    }
}

private final class RecordingWiFiRunner: CommandRunning {
    var executedCommands: [[String]] = []
    var hardwarePortOutput: String = ""

    func run(executablePath: String, arguments: [String]) throws {
        executedCommands.append([executablePath] + arguments)
    }

    func runAndCaptureOutput(executablePath: String, arguments: [String]) throws -> String {
        executedCommands.append([executablePath] + arguments)
        return hardwarePortOutput
    }
}

private final class MutableNow {
    var date: Date

    init(date: Date) {
        self.date = date
    }

    func current() -> Date {
        date
    }
}
