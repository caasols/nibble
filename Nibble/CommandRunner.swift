import Foundation

protocol CommandRunning {
    func run(executablePath: String, arguments: [String]) throws
    func runAndCaptureOutput(executablePath: String, arguments: [String]) throws -> String
}

enum CommandRunnerError: Error {
    case executionFailed(String)
}

struct ProcessCommandRunner: CommandRunning {
    func run(executablePath: String, arguments: [String]) throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executablePath)
        task.arguments = arguments
        task.standardOutput = Pipe()
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            throw CommandRunnerError.executionFailed(error.localizedDescription)
        }

        guard task.terminationStatus == 0 else {
            throw CommandRunnerError.executionFailed("Command exited with status \(task.terminationStatus)")
        }
    }

    func runAndCaptureOutput(executablePath: String, arguments: [String]) throws -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executablePath)
        task.arguments = arguments

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            throw CommandRunnerError.executionFailed(error.localizedDescription)
        }

        guard task.terminationStatus == 0 else {
            throw CommandRunnerError.executionFailed("Command exited with status \(task.terminationStatus)")
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
