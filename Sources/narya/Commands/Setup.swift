// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ArgumentParser
import Foundation

struct Setup: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Clone the firefox-ios repository."
    )

    @Flag(name: .long, help: "Use SSH URL for cloning (git@github.com:...) instead of HTTPS.")
    var ssh = false

    @Option(name: .long, help: "Directory path (absolute or relative) to clone into. Defaults to current directory.")
    var location: String?

    mutating func run() throws {
        try requireGitAvailable()

        let repoURL = ssh
            ? "git@github.com:mozilla-mobile/firefox-ios.git"
            : "https://github.com/mozilla-mobile/firefox-ios.git"

        var arguments = ["clone", repoURL]
        if let location = location {
            arguments.append(location)
        }

        print("Cloning firefox-ios. This may take a while. Grab a coffee. Go pet a fox.")
        try runGit(arguments: arguments)
        print("Cloning done.")
    }

    private func requireGitAvailable() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "--version"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw SetupError.gitNotFound
            }
        } catch {
            throw SetupError.gitNotFound
        }
    }

    private func runGit(arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw SetupError.gitCloneFailed(exitCode: process.terminationStatus)
        }
    }
}

enum SetupError: Error, CustomStringConvertible {
    case gitNotFound
    case gitCloneFailed(exitCode: Int32)

    var description: String {
        switch self {
        case .gitNotFound:
            return "git is not available. Please install git and try again."
        case .gitCloneFailed(let exitCode):
            return "git clone failed with exit code \(exitCode)."
        }
    }
}
