import Testing
@testable import Nibble

struct DNSFlushServiceTests {
    @Test func executesExpectedFlushCommandsInOrder() {
        let runner = RecordingCommandRunner()
        let service = DNSFlushService(commandRunner: runner)

        let result = service.flushDNSCache()

        #expect(result.isSuccess == true)
        #expect(runner.executedCommands == [
            ["/usr/bin/dscacheutil", "-flushcache"],
            ["/usr/bin/killall", "-HUP", "mDNSResponder"]
        ])
    }

    @Test func returnsFailureWhenACommandErrors() {
        let runner = RecordingCommandRunner()
        runner.failureAtCommandIndex = 1
        let service = DNSFlushService(commandRunner: runner)

        let result = service.flushDNSCache()

        #expect(result.isSuccess == false)
    }
}

private final class RecordingCommandRunner: CommandRunning {
    var executedCommands: [[String]] = []
    var failureAtCommandIndex: Int?

    func run(executablePath: String, arguments: [String]) throws {
        executedCommands.append([executablePath] + arguments)
        if failureAtCommandIndex == executedCommands.count - 1 {
            throw CommandRunnerError.executionFailed("simulated")
        }
    }

    func runAndCaptureOutput(executablePath: String, arguments: [String]) throws -> String {
        executedCommands.append([executablePath] + arguments)
        return ""
    }
}
