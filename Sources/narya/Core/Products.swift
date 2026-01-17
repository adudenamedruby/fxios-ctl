// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ArgumentParser
import Foundation

// MARK: - Build Product

/// Represents the available products that can be built, run, or tested
enum BuildProduct: String, ExpressibleByArgument, CaseIterable {
    case firefox
    case focus
    case klar

    var scheme: String {
        switch self {
        case .firefox: return "Fennec"
        case .focus: return "Focus"
        case .klar: return "Klar"
        }
    }

    var projectPath: String {
        switch self {
        case .firefox: return "firefox-ios/Client.xcodeproj"
        case .focus, .klar: return "focus-ios/Blockzilla.xcodeproj"
        }
    }

    var defaultConfiguration: String {
        switch self {
        case .firefox: return "Fennec"
        case .focus: return "FocusDebug"
        case .klar: return "KlarDebug"
        }
    }

    var testingConfiguration: String {
        switch self {
        case .firefox: return "Fennec_Testing"
        case .focus: return "FocusDebug"
        case .klar: return "KlarDebug"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .firefox: return "org.mozilla.ios.Fennec"
        case .focus: return "org.mozilla.ios.Focus"
        case .klar: return "org.mozilla.ios.Klar"
        }
    }
}
