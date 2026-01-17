// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ArgumentParser
import Foundation

struct Nimbus: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Manage Nimbus feature configuration files.",
        discussion: """
            Manages Nimbus feature flags across the firefox-ios codebase.

            Use 'refresh' to update the include block in nimbus.fml.yaml.
            Use 'add' to create a new feature with all required boilerplate.
            Use 'remove' to remove a feature from all locations.
            """,
        subcommands: [Refresh.self, Add.self, Remove.self]
    )
}

// MARK: - Constants

enum NimbusConstants {
    static let nimbusFmlPath = "firefox-ios/nimbus.fml.yaml"
    static let nimbusFeaturesPath = "firefox-ios/nimbus-features"
    static let nimbusFlaggableFeaturePath = "firefox-ios/Client/FeatureFlags/NimbusFlaggableFeature.swift"
    static let nimbusFeatureFlagLayerPath = "firefox-ios/Client/Nimbus/NimbusFeatureFlagLayer.swift"
    static let featureFlagsDebugViewControllerPath = "firefox-ios/Client/Frontend/Settings/Main/Debug/FeatureFlags/FeatureFlagsDebugViewController.swift"
}

// MARK: - Refresh Subcommand

extension Nimbus {
    struct Refresh: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Refresh the include block in nimbus.fml.yaml with current feature files."
        )

        mutating func run() throws {
            Herald.reset()

            let repo = try RepoDetector.requireValidRepo()

            Herald.declare("Updating nimbus.fml.yaml include block...")
            try NimbusHelpers.updateNimbusFml(repoRoot: repo.root)
            Herald.declare("Successfully updated nimbus.fml.yaml")
        }
    }
}

// MARK: - Add Subcommand

extension Nimbus {
    struct Add: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Add a new Nimbus feature flag.",
            discussion: """
                Creates a new feature YAML file and adds the feature to all required Swift files.

                The feature name should be in camelCase without the 'Feature' suffix.
                For example: 'testButtress' will create 'testButtressFeature.yaml'.
                """
        )

        @Argument(help: "The feature name in camelCase (without 'Feature' suffix).")
        var featureName: String

        @Flag(name: .long, help: "Add the feature to the debug settings UI.")
        var debug = false

        @Flag(name: .long, help: "Mark the feature as user-toggleable (requires implementing a preference key).")
        var userToggleable = false

        mutating func run() throws {
            Herald.reset()

            let repo = try RepoDetector.requireValidRepo()

            // Standardize the feature name (remove Feature suffix if present)
            let cleanName = NimbusHelpers.cleanFeatureName(featureName)

            Herald.declare("Adding feature '\(cleanName)'...")

            // 1. Create the YAML file
            let yamlFileName = "\(cleanName)Feature.yaml"
            let yamlFilePath = repo.root
                .appendingPathComponent(NimbusConstants.nimbusFeaturesPath)
                .appendingPathComponent(yamlFileName)

            Herald.declare("Creating feature file: \(NimbusConstants.nimbusFeaturesPath)/\(yamlFileName)")
            try NimbusHelpers.writeFeatureTemplate(to: yamlFilePath, featureName: "\(cleanName)Feature")

            // 2. Update nimbus.fml.yaml
            Herald.declare("Updating nimbus.fml.yaml...")
            try NimbusHelpers.updateNimbusFml(repoRoot: repo.root)

            // 3. Update NimbusFlaggableFeature.swift
            let flaggableFeaturePath = repo.root.appendingPathComponent(NimbusConstants.nimbusFlaggableFeaturePath)
            Herald.declare("Updating NimbusFlaggableFeature.swift...")
            try NimbusFlaggableFeatureEditor.addFeature(
                name: cleanName,
                debug: debug,
                userToggleable: userToggleable,
                filePath: flaggableFeaturePath
            )

            // 4. Update NimbusFeatureFlagLayer.swift
            let flagLayerPath = repo.root.appendingPathComponent(NimbusConstants.nimbusFeatureFlagLayerPath)
            Herald.declare("Updating NimbusFeatureFlagLayer.swift...")
            try NimbusFeatureFlagLayerEditor.addFeature(name: cleanName, filePath: flagLayerPath)

            // 5. If --debug, update FeatureFlagsDebugViewController.swift
            if debug {
                let debugVCPath = repo.root.appendingPathComponent(NimbusConstants.featureFlagsDebugViewControllerPath)
                Herald.declare("Updating FeatureFlagsDebugViewController.swift...")
                try FeatureFlagsDebugViewControllerEditor.addFeature(name: cleanName, filePath: debugVCPath)
            }

            Herald.declare("Successfully added feature '\(cleanName)'")
            Herald.declare("Please remember to add this feature to the feature flag spreadsheet.")
        }
    }
}

// MARK: - Remove Subcommand

extension Nimbus {
    struct Remove: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove a Nimbus feature flag.",
            discussion: """
                Removes a feature from all locations where it was added.

                The command will validate that all patterns match exactly before removing anything.
                If any validation fails, no changes will be made.
                """
        )

        @Argument(help: "The feature name in camelCase (without 'Feature' suffix).")
        var featureName: String

        mutating func run() throws {
            Herald.reset()

            let repo = try RepoDetector.requireValidRepo()

            // Standardize the feature name
            let cleanName = NimbusHelpers.cleanFeatureName(featureName)

            Herald.declare("Removing feature '\(cleanName)'...")

            // Collect all file paths
            let yamlFileName = "\(cleanName)Feature.yaml"
            let yamlFilePath = repo.root
                .appendingPathComponent(NimbusConstants.nimbusFeaturesPath)
                .appendingPathComponent(yamlFileName)
            let flaggableFeaturePath = repo.root.appendingPathComponent(NimbusConstants.nimbusFlaggableFeaturePath)
            let flagLayerPath = repo.root.appendingPathComponent(NimbusConstants.nimbusFeatureFlagLayerPath)
            let debugVCPath = repo.root.appendingPathComponent(NimbusConstants.featureFlagsDebugViewControllerPath)

            // Phase 1: Validate all removals are possible
            Herald.declare("Validating removal...")

            // Check YAML file exists
            guard FileManager.default.fileExists(atPath: yamlFilePath.path) else {
                throw ValidationError("Feature YAML file not found: \(yamlFilePath.path)")
            }

            // Validate NimbusFlaggableFeature.swift
            let flaggableValidation = try NimbusFlaggableFeatureEditor.validateRemoval(
                name: cleanName,
                filePath: flaggableFeaturePath
            )

            // Validate NimbusFeatureFlagLayer.swift
            try NimbusFeatureFlagLayerEditor.validateRemoval(name: cleanName, filePath: flagLayerPath)

            // Check if feature is in debug settings
            let isInDebugVC = try FeatureFlagsDebugViewControllerEditor.featureExists(
                name: cleanName,
                filePath: debugVCPath
            )

            // Phase 2: Perform all removals
            Herald.declare("Removing from all locations...")

            // Remove YAML file
            Herald.declare("Removing feature file: \(NimbusConstants.nimbusFeaturesPath)/\(yamlFileName)")
            try FileManager.default.removeItem(at: yamlFilePath)

            // Update nimbus.fml.yaml
            Herald.declare("Updating nimbus.fml.yaml...")
            try NimbusHelpers.updateNimbusFml(repoRoot: repo.root)

            // Remove from NimbusFlaggableFeature.swift
            Herald.declare("Updating NimbusFlaggableFeature.swift...")
            try NimbusFlaggableFeatureEditor.removeFeature(
                name: cleanName,
                isInDebugKey: flaggableValidation.isInDebugKey,
                isUserToggleable: flaggableValidation.isUserToggleable,
                filePath: flaggableFeaturePath
            )

            // Remove from NimbusFeatureFlagLayer.swift
            Herald.declare("Updating NimbusFeatureFlagLayer.swift...")
            try NimbusFeatureFlagLayerEditor.removeFeature(name: cleanName, filePath: flagLayerPath)

            // Remove from FeatureFlagsDebugViewController.swift if present
            if isInDebugVC {
                Herald.declare("Updating FeatureFlagsDebugViewController.swift...")
                try FeatureFlagsDebugViewControllerEditor.removeFeature(name: cleanName, filePath: debugVCPath)
            }

            Herald.declare("Successfully removed feature '\(cleanName)'")
        }
    }
}

// MARK: - Shared Helpers

enum NimbusHelpers {
    /// Removes the "Feature" suffix from a feature name if present
    static func cleanFeatureName(_ input: String) -> String {
        if input.hasSuffix("Feature") {
            return String(input.dropLast(7))
        }
        return input
    }

    /// Converts camelCase to kebab-case
    static func camelToKebabCase(_ input: String) -> String {
        StringUtils.camelToKebabCase(input)
    }

    /// Converts camelCase to Title Case (e.g., "testButtress" -> "Test Buttress")
    static func camelToTitleCase(_ input: String) -> String {
        StringUtils.camelToTitleCase(input)
    }

    /// Capitalizes the first letter of a string
    static func capitalizeFirst(_ input: String) -> String {
        StringUtils.capitalizeFirst(input)
    }

    /// Updates the nimbus.fml.yaml include block with current feature files
    static func updateNimbusFml(repoRoot: URL) throws {
        let fmlPath = repoRoot.appendingPathComponent(NimbusConstants.nimbusFmlPath)

        guard FileManager.default.fileExists(atPath: fmlPath.path) else {
            throw ValidationError("nimbus.fml.yaml not found at \(fmlPath.path)")
        }

        // Read current content
        var content = try String(contentsOf: fmlPath, encoding: .utf8)

        // Remove existing nimbus-features lines
        let lines = content.components(separatedBy: "\n")
        let filteredLines = lines.filter { !$0.contains("nimbus-features") }
        content = filteredLines.joined(separator: "\n")

        // Add feature files
        let featuresDir = repoRoot.appendingPathComponent(NimbusConstants.nimbusFeaturesPath)
        if FileManager.default.fileExists(atPath: featuresDir.path) {
            let yamlFiles = try FileManager.default.contentsOfDirectory(at: featuresDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "yaml" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            for file in yamlFiles {
                let relativePath = "nimbus-features/\(file.lastPathComponent)"
                content += "\n  - \(relativePath)"
            }
        }

        try content.write(to: fmlPath, atomically: true, encoding: .utf8)
    }

    /// Writes the feature YAML template
    static func writeFeatureTemplate(to url: URL, featureName: String) throws {
        let kebabName = camelToKebabCase(featureName)

        let template = """
            # The configuration for the \(featureName) feature
            features:
              \(kebabName):
                description: >
                  Feature description
                variables:
                  enabled:
                    description: >
                      Whether or not this feature is enabled
                    type: Boolean
                    default: false
                defaults:
                  - channel: beta
                    value:
                      enabled: false
                  - channel: developer
                    value:
                      enabled: true
            """
        try template.write(to: url, atomically: true, encoding: .utf8)
    }
}
