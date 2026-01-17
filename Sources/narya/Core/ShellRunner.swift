// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Errors

enum ShellRunnerError: Error, CustomStringConvertible {
    case commandFailed(command: String, exitCode: Int32)
    case executionFailed(command: String, reason: String)

    var description: String {
        switch self {
        case .commandFailed(let command, let exitCode):
            return "\(command) failed with exit code \(exitCode)."
        case .executionFailed(let command, let reason):
            return "Failed to execute \(command): \(reason)"
        }
    }
}

// MARK: - ShellRunner

/// Executes shell commands via `/usr/bin/env`.
///
/// Two variants are provided:
/// - `run`: Streams output directly to the terminal
/// - `runAndCapture`: Captures stdout and returns it as a String
enum ShellRunner {
    /// Runs a command, streaming output to the terminal.
    @discardableResult
    static func run(
        _ command: String,
        arguments: [String] = [],
        workingDirectory: URL? = nil
    ) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }

        do {
            try process.run()
        } catch {
            throw ShellRunnerError.executionFailed(
                command: command,
                reason: error.localizedDescription
            )
        }

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw ShellRunnerError.commandFailed(
                command: command,
                exitCode: process.terminationStatus
            )
        }

        return process.terminationStatus
    }

    /// Runs a command and captures stdout, suppressing stderr.
    static func runAndCapture(
        _ command: String,
        arguments: [String] = [],
        workingDirectory: URL? = nil
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw ShellRunnerError.executionFailed(
                command: command,
                reason: error.localizedDescription
            )
        }

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw ShellRunnerError.commandFailed(
                command: command,
                exitCode: process.terminationStatus
            )
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
