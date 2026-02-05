// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Handles formatted output for fxios commands.
/// The first line of output uses 🦊, subsequent lines use ▒
enum Herald {
    private static let indentChar = "▒"

    // State tracking: after a conclusion, subsequent calls use normal continuation
    nonisolated(unsafe) private static var hadConclusion = false

    /// Declares a message with formatted prefix based on context.
    ///
    /// Output prefixes:
    /// - `isNewCommand: true`: `🦊` (or `🦊 💥` if asError)
    /// - Normal continuation: `▒` (or `▒ 💥` if asError)
    /// - First conclusion: `🦊` (or `🦊 💥` if asError)
    /// - Post-conclusion: `▒` (asError and asConclusion ignored)
    ///
    /// Multi-line messages use `▒ ▒` prefix for lines after the first.
    ///
    /// - Parameters:
    ///   - message: The message to display
    ///   - asError: If true, adds 💥 to indicate an error/warning
    ///   - isNewCommand: If true, resets state and uses 🦊 prefix
    ///   - asConclusion: If true, uses 🦊 prefix (first time only)
    static func declare(
        _ message: String,
        asError: Bool = false,
        isNewCommand: Bool = false,
        asConclusion: Bool = false
    ) {
        // Reset state if new command
        if isNewCommand {
            hadConclusion = false
        }

        let lines = message.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let prefix: String

            if index == 0 {
                // First line of this message
                if isNewCommand {
                    prefix = asError ? "🦊 💥" : "🦊"
                } else if hadConclusion {
                    // After a conclusion, subsequent calls are normal continuation
                    prefix = indentChar
                } else if asConclusion {
                    prefix = asError ? "🦊 💥" : "🦊"
                } else {
                    prefix = asError ? "\(indentChar) 💥" : indentChar
                }
            } else {
                // Subsequent lines of multi-line message use sub-continuation
                prefix = "\(indentChar) \(indentChar)"
            }

            Swift.print("\(prefix) \(line)")
        }

        // Update state after printing
        if asConclusion && !hadConclusion {
            hadConclusion = true
        }
    }

    /// Outputs raw text without Herald formatting.
    /// Use for command output in --expose mode where users need copy-pasteable commands.
    static func raw(_ message: String) {
        Swift.print(message)
    }
}
