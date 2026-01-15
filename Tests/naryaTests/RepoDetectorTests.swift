// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing
@testable import narya

@Suite("RepoDetector Tests")
struct RepoDetectorTests {
    let fileManager = FileManager.default

    func createTempDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanup(_ url: URL) {
        try? fileManager.removeItem(at: url)
    }

    @Test("Finds marker file in current directory")
    func findsMarkerInCurrentDir() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let markerPath = tempDir.appendingPathComponent(Configuration.markerFileName)
        try "project: firefox-ios".write(to: markerPath, atomically: true, encoding: .utf8)

        let found = RepoDetector.findMarkerFile(startingAt: tempDir, searchParents: false)
        #expect(found != nil)
        #expect(found?.lastPathComponent == Configuration.markerFileName)
    }

    @Test("Finds marker file in parent directory")
    func findsMarkerInParentDir() throws {
        let parentDir = try createTempDirectory()
        defer { cleanup(parentDir) }

        let childDir = parentDir.appendingPathComponent("subdir")
        try fileManager.createDirectory(at: childDir, withIntermediateDirectories: true)

        let markerPath = parentDir.appendingPathComponent(Configuration.markerFileName)
        try "project: firefox-ios".write(to: markerPath, atomically: true, encoding: .utf8)

        let found = RepoDetector.findMarkerFile(startingAt: childDir, searchParents: true)
        #expect(found != nil)
        #expect(found?.deletingLastPathComponent().lastPathComponent == parentDir.lastPathComponent)
    }

    @Test("Returns nil when marker not found")
    func returnsNilWhenNotFound() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let found = RepoDetector.findMarkerFile(startingAt: tempDir, searchParents: false)
        #expect(found == nil)
    }

    @Test("Loads valid config from marker file")
    func loadsValidConfig() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let markerPath = tempDir.appendingPathComponent(Configuration.markerFileName)
        try "project: firefox-ios".write(to: markerPath, atomically: true, encoding: .utf8)

        let config = try RepoDetector.loadConfig(from: markerPath)
        #expect(config.project == "firefox-ios")
    }

    @Test("Throws error for invalid YAML")
    func throwsForInvalidYaml() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let markerPath = tempDir.appendingPathComponent(Configuration.markerFileName)
        try "not: valid: yaml: here".write(to: markerPath, atomically: true, encoding: .utf8)

        #expect(throws: RepoDetectorError.self) {
            _ = try RepoDetector.loadConfig(from: markerPath)
        }
    }

    @Test("requireValidRepo succeeds with correct project")
    func requireValidRepoSucceeds() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let markerPath = tempDir.appendingPathComponent(Configuration.markerFileName)
        try "project: firefox-ios".write(to: markerPath, atomically: true, encoding: .utf8)

        let config = try RepoDetector.requireValidRepo(startingAt: tempDir)
        #expect(config.project == "firefox-ios")
    }

    @Test("requireValidRepo throws for wrong project")
    func requireValidRepoThrowsForWrongProject() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let markerPath = tempDir.appendingPathComponent(Configuration.markerFileName)
        try "project: some-other-project".write(to: markerPath, atomically: true, encoding: .utf8)

        #expect(throws: RepoDetectorError.self) {
            _ = try RepoDetector.requireValidRepo(startingAt: tempDir)
        }
    }

    @Test("requireValidRepo throws when marker not found")
    func requireValidRepoThrowsWhenNotFound() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        #expect(throws: RepoDetectorError.self) {
            _ = try RepoDetector.requireValidRepo(startingAt: tempDir)
        }
    }
}
