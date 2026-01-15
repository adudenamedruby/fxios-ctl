// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
@testable import narya

@Suite("Configuration Tests")
struct ConfigurationTests {
    @Test("Configuration has correct name")
    func name() {
        #expect(Configuration.name == "narya")
    }

    @Test("Configuration has valid version format")
    func versionFormat() {
        let versionPattern = /^\d+\.\d+\.\d+$/
        #expect(Configuration.version.contains(versionPattern))
    }

    @Test("Configuration has non-empty description")
    func description() {
        #expect(!Configuration.shortDescription.isEmpty)
    }

    @Test("About text contains name and version")
    func aboutText() {
        #expect(Configuration.aboutText.contains(Configuration.name))
        #expect(Configuration.aboutText.contains(Configuration.version))
    }

    @Test("Marker file name is .narya.yaml")
    func markerFileName() {
        #expect(Configuration.markerFileName == ".narya.yaml")
    }
}
