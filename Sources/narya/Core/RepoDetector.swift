// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Yams

struct NaryaConfig: Codable {
    let project: String
}

enum RepoDetectorError: Error, CustomStringConvertible {
    case markerNotFound
    case invalidMarkerFile(String)
    case unexpectedProject(expected: String, found: String)

    var description: String {
        switch self {
        case .markerNotFound:
            return """
                Not a narya-compatible repository.
                Expected \(Configuration.markerFileName) in project root.
                Are you in the firefox-ios directory?
                """
        case .invalidMarkerFile(let reason):
            return "Invalid \(Configuration.markerFileName): \(reason)"
        case .unexpectedProject(let expected, let found):
            return """
                Unexpected project in \(Configuration.markerFileName).
                Expected: \(expected), found: \(found)
                """
        }
    }
}

enum RepoDetector {
    static let expectedProject = "firefox-ios"

    static func findMarkerFile(
        startingAt directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        searchParents: Bool = true
    ) -> URL? {
        var currentDir = directory.standardizedFileURL

        while true {
            let markerPath = currentDir.appendingPathComponent(Configuration.markerFileName)
            if FileManager.default.fileExists(atPath: markerPath.path) {
                return markerPath
            }

            if !searchParents {
                break
            }

            let parent = currentDir.deletingLastPathComponent().standardizedFileURL
            if parent.path == currentDir.path {
                break
            }
            currentDir = parent
        }

        return nil
    }

    static func loadConfig(from markerPath: URL) throws -> NaryaConfig {
        let contents: String
        do {
            contents = try String(contentsOf: markerPath, encoding: .utf8)
        } catch {
            throw RepoDetectorError.invalidMarkerFile("Could not read file: \(error.localizedDescription)")
        }

        do {
            let config = try YAMLDecoder().decode(NaryaConfig.self, from: contents)
            return config
        } catch {
            throw RepoDetectorError.invalidMarkerFile("Could not parse YAML: \(error.localizedDescription)")
        }
    }

    static func requireValidRepo(
        startingAt directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    ) throws -> NaryaConfig {
        guard let markerPath = findMarkerFile(startingAt: directory) else {
            throw RepoDetectorError.markerNotFound
        }

        let config = try loadConfig(from: markerPath)

        guard config.project == expectedProject else {
            throw RepoDetectorError.unexpectedProject(
                expected: expectedProject,
                found: config.project
            )
        }

        return config
    }
}
