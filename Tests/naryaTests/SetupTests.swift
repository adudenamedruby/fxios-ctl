// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
@testable import narya

@Suite("Setup Tests")
struct SetupTests {
    @Test("SetupError.gitNotFound has correct description")
    func gitNotFoundDescription() {
        let error = SetupError.gitNotFound
        #expect(error.description.contains("git is not available"))
    }

    @Test("SetupError.gitCloneFailed includes exit code")
    func gitCloneFailedDescription() {
        let error = SetupError.gitCloneFailed(exitCode: 128)
        #expect(error.description.contains("128"))
        #expect(error.description.contains("failed"))
    }
}
