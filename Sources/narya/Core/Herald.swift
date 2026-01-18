// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Handles formatted output for narya commands.
/// The first line of output uses 💍, subsequent lines use ▒
enum Herald {
    // This is a CLI tool that runs single-threaded, so mutable global state is safe
    nonisolated(unsafe) private static var isFirstLine = true

    /// Resets the output state for a new command execution
    static func reset() {
        isFirstLine = true
    }

    /// Declares a message with formatted prefix based on context.
    ///
    /// Output prefixes:
    /// - First line: `💍` (or `💍 💥` if asError)
    /// - Subsequent lines: `▒` (or `▒ 💥` if asError)
    /// - Conclusion lines: `💍` (or `💍 💥` if asError)
    ///
    /// Multi-line messages use `▒ ▒ ` prefix for lines after the first.
    ///
    /// - Parameters:
    ///   - message: The message to display
    ///   - asError: If true, adds 💥 to indicate an error/warning
    ///   - asConclusion: If true, uses 💍 prefix regardless of position (visual only, doesn't reset state)
    static func declare(
        _ message: String,
        asError: Bool = false,
        asConclusion: Bool = false
    ) {
        let lines = message.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let prefix: String
            if index == 0 {
                // First line of this message
                let useRingPrefix = isFirstLine || asConclusion
                if useRingPrefix {
                    prefix = asError ? "💍 💥" : "💍"
                } else {
                    prefix = asError ? "▒ 💥" : "▒"
                }
            } else {
                // Subsequent lines of multi-line message
                prefix = "▒ ▒"
            }

            Swift.print("\(prefix) \(line)")
        }

        // Only the first call sets isFirstLine to false
        // asConclusion does NOT reset state
        isFirstLine = false
    }
}
