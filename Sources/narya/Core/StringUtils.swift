// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - String Utilities

/// Common string transformation utilities used across commands
enum StringUtils {
    /// Converts camelCase to snake_case (e.g., "testButtress" -> "test_buttress")
    static func camelToSnakeCase(_ input: String) -> String {
        var result = ""
        for (index, char) in input.enumerated() {
            if char.isUppercase && index > 0 {
                result += "_"
            }
            result += char.lowercased()
        }
        return result
    }

    /// Converts camelCase to kebab-case (e.g., "testButtress" -> "test-buttress")
    static func camelToKebabCase(_ input: String) -> String {
        var result = ""
        for (index, char) in input.enumerated() {
            if char.isUppercase && index > 0 {
                result += "-"
            }
            result += char.lowercased()
        }
        return result
    }

    /// Converts camelCase to Title Case (e.g., "testButtress" -> "Test Buttress")
    static func camelToTitleCase(_ input: String) -> String {
        var result = ""
        for (index, char) in input.enumerated() {
            if char.isUppercase && index > 0 {
                result += " "
            }
            if index == 0 {
                result += char.uppercased()
            } else {
                result += String(char)
            }
        }
        return result
    }

    /// Capitalizes the first letter of a string (e.g., "test" -> "Test")
    static func capitalizeFirst(_ input: String) -> String {
        guard let first = input.first else { return input }
        return first.uppercased() + input.dropFirst()
    }
}
