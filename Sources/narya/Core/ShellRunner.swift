// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Errors

enum ShellRunnerError: Error, CustomStringConvertible {
    case commandFailed(command: String, exitCode: Int32)
    case executionFailed(command: String, reason: String)
    case timedOut(command: String, timeout: TimeInterval)

    var description: String {
        switch self {
        case .commandFailed(let command, let exitCode):
            return "\(command) failed with exit code \(exitCode)."
        case .executionFailed(let command, let reason):
            return "Failed to execute \(command): \(reason)"
        case .timedOut(let command, let timeout):
            return "\(command) timed out after \(Int(timeout)) seconds."
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
        Logger.debug("Executing: \(command) \(arguments.joined(separator: " "))")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = workingDirectory
            Logger.debug("Working directory: \(workingDirectory.path)")
        }

        do {
            try process.run()
        } catch {
            Logger.error("Failed to execute \(command)", error: error)
            throw ShellRunnerError.executionFailed(
                command: command,
                reason: error.localizedDescription
            )
        }

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            Logger.debug("\(command) exited with code \(process.terminationStatus)")
            throw ShellRunnerError.commandFailed(
                command: command,
                exitCode: process.terminationStatus
            )
        }

        Logger.debug("\(command) completed successfully")
        return process.terminationStatus
    }

    /// Runs a command and captures stdout, suppressing stderr.
    /// - Parameters:
    ///   - command: The command to execute
    ///   - arguments: Arguments to pass to the command
    ///   - workingDirectory: Optional working directory
    ///   - timeout: Optional timeout in seconds. If nil, waits indefinitely.
    /// - Returns: The captured stdout as a String
    /// - Throws: ShellRunnerError if the command fails, can't be executed, or times out
    static func runAndCapture(
        _ command: String,
        arguments: [String] = [],
        workingDirectory: URL? = nil,
        timeout: TimeInterval? = nil
    ) throws -> String {
        Logger.debug("Executing (capture): \(command) \(arguments.joined(separator: " "))")
        if let timeout = timeout {
            Logger.debug("Timeout: \(timeout) seconds")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = workingDirectory
            Logger.debug("Working directory: \(workingDirectory.path)")
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            Logger.error("Failed to execute \(command)", error: error)
            throw ShellRunnerError.executionFailed(
                command: command,
                reason: error.localizedDescription
            )
        }

        // If timeout is specified, wait with timeout; otherwise wait indefinitely
        if let timeout = timeout {
            let semaphore = DispatchSemaphore(value: 0)

            // Set up termination handler to signal completion
            process.terminationHandler = { _ in
                semaphore.signal()
            }

            // Wait for process to complete or timeout
            let result = semaphore.wait(timeout: .now() + timeout)

            if result == .timedOut {
                Logger.debug("\(command) timed out after \(timeout) seconds, terminating process")
                process.terminate()
                // Give the process a moment to terminate gracefully
                Thread.sleep(forTimeInterval: 0.1)
                if process.isRunning {
                    // Force kill if still running
                    kill(process.processIdentifier, SIGKILL)
                }
                throw ShellRunnerError.timedOut(command: command, timeout: timeout)
            }
        } else {
            process.waitUntilExit()
        }

        if process.terminationStatus != 0 {
            Logger.debug("\(command) exited with code \(process.terminationStatus)")
            throw ShellRunnerError.commandFailed(
                command: command,
                exitCode: process.terminationStatus
            )
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        Logger.debug("\(command) completed, captured \(data.count) bytes")
        return String(data: data, encoding: .utf8) ?? ""
    }
}
