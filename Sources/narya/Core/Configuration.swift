// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum Configuration {
    static let name = "narya"
    static let version = "0.1.0"
    static let shortDescription = "A helper CLI for the firefox-ios repository"
    static let longDescription = """
        narya provides a single entry point for running common tasks,
        automations, and workflows used in the development of firefox-ios.

        The name comes from Narya, the Ring of Fire borne by Gandalf in
        Tolkien’s legendarium — a symbol of endurance, guidance, and the
        ability to inspire others to action.
        """
    static let markerFileName = ".narya.yaml"

    static var aboutText: String {
        """
        \(name) (version \(version))

        \(longDescription)
        """
    }
}
