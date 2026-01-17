// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ArgumentParser
import Foundation
import Testing
@testable import narya

@Suite("Doctor Tests", .serialized)
struct DoctorTests {
    @Test("Command has correct name")
    func commandHasCorrectName() {
        #expect(Doctor.configuration.commandName == "doctor")
    }

    @Test("Command has non-empty abstract")
    func commandHasAbstract() {
        let abstract = Doctor.configuration.abstract
        #expect(!abstract.isEmpty)
    }

    @Test("Command can be parsed with no arguments")
    func canParseWithNoArguments() throws {
        let command = try Doctor.parse([])
        #expect(type(of: command) == Doctor.self)
    }

    @Test("Command is registered as subcommand of Narya")
    func isRegisteredSubcommand() {
        let subcommands = Narya.configuration.subcommands
        let doctorType = subcommands.first { $0 == Doctor.self }
        #expect(doctorType != nil)
    }
}
