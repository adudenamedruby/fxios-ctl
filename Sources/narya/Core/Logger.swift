// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Log levels for debug output
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Debug logging utility for narya.
/// Enabled via --debug flag. Output goes to stderr to not interfere with normal output.
enum Logger {
    /// Global debug mode flag - set by main() when --debug is passed
    nonisolated(unsafe) static var isDebugEnabled = false

    /// Minimum log level to display (default: debug when enabled)
    nonisolated(unsafe) static var minimumLevel: LogLevel = .debug

    /// Logs a debug message (only shown when --debug is enabled)
    static func debug(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .debug, message(), file: file, line: line)
    }

    /// Logs an info message
    static func info(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .info, message(), file: file, line: line)
    }

    /// Logs a warning message
    static func warning(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .warning, message(), file: file, line: line)
    }

    /// Logs an error with optional underlying error details
    static func error(_ message: @autoclosure () -> String, error: Error? = nil, file: String = #file, line: Int = #line) {
        var fullMessage = message()
        if let error = error {
            fullMessage += "\n  Underlying error: \(error)"
            if isDebugEnabled {
                fullMessage += "\n  Error type: \(type(of: error))"
            }
        }
        log(level: .error, fullMessage, file: file, line: line)
    }

    private static func log(level: LogLevel, _ message: String, file: String, line: Int) {
        guard isDebugEnabled && level >= minimumLevel else { return }

        let filename = URL(fileURLWithPath: file).lastPathComponent
        let prefix: String
        switch level {
        case .debug: prefix = "[DEBUG]"
        case .info: prefix = "[INFO]"
        case .warning: prefix = "[WARN]"
        case .error: prefix = "[ERROR]"
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        fputs("\(timestamp) \(prefix) \(filename):\(line) - \(message)\n", stderr)
    }
}
