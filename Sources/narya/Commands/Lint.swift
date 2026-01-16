// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ArgumentParser
import Foundation

// MARK: - Lint Product

enum LintProduct: String, ExpressibleByArgument, CaseIterable {
    case firefox
    case focus

    var directory: String {
        switch self {
        case .firefox: return "firefox-ios"
        case .focus: return "focus-ios"
        }
    }
}

// MARK: - Lint Errors

enum LintError: Error, CustomStringConvertible {
    case swiftlintNotFound
    case lintFailed(exitCode: Int32)
    case noChangedFiles

    var description: String {
        switch self {
        case .swiftlintNotFound:
            return "💥💍 swiftlint not found. Install it with 'brew install swiftlint'."
        case .lintFailed(let exitCode):
            return "💥💍 Linting failed with exit code \(exitCode)."
        case .noChangedFiles:
            return "💥💍 No changed Swift files found."
        }
    }
}

// MARK: - Lint Command

struct Lint: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lint",
        abstract: "Run SwiftLint on the codebase.",
        discussion: """
            Runs SwiftLint on the specified product. By default, lints only files \
            changed compared to the main branch.

            This is not meant to replace swiftlint; merely be a simplified \
            entry-point for development. Please consult swiftlint for the full \
            capabilites of that tool if you need to use it.
            """,
        subcommands: [LintInfo.self]
    )

    // MARK: - Product Selection

    @Option(name: [.short, .long], help: "Product to lint: firefox or focus.")
    var product: LintProduct = .firefox

    // MARK: - Scope

    @Flag(name: [.short, .long], help: "Lint only files changed compared to main branch (default).")
    var changed = false

    @Flag(name: [.short, .long], help: "Lint the entire project instead of just changed files.")
    var all = false

    // MARK: - Options

    @Flag(name: [.short, .long], help: "Treat warnings as errors.")
    var strict = false

    @Flag(name: [.short, .long], help: "Show only violation counts.")
    var quiet = false

    @Flag(name: .long, help: "Automatically correct fixable violations.")
    var fix = false

    // MARK: - Run

    mutating func run() throws {
        Herald.reset()

        // Validate we're in a firefox-ios repository
        let repo = try RepoDetector.requireValidRepo()

        // Check for swiftlint
        try requireSwiftlint()

        // Determine the target directory
        let targetDir = repo.root.appendingPathComponent(product.directory)
        guard FileManager.default.fileExists(atPath: targetDir.path) else {
            throw ValidationError("💥💍 Directory not found: \(product.directory)")
        }

        // Determine if we should lint all or just changed files
        // Default is changed (unless --all is specified)
        let lintAll = all || (!changed && !all && fix)  // --fix implies --all unless --changed specified

        if fix {
            try runFix(targetDir: targetDir, lintAll: lintAll, repoRoot: repo.root)
        } else {
            try runLint(targetDir: targetDir, lintAll: lintAll, repoRoot: repo.root)
        }
    }

    // MARK: - Lint

    private func runLint(targetDir: URL, lintAll: Bool, repoRoot: URL) throws {
        var args: [String] = ["lint"]

        if strict {
            args.append("--strict")
        }

        if quiet {
            args.append("--quiet")
        }

        if lintAll {
            Herald.declare("Linting all files in \(product.directory)...")
            args.append("--path")
            args.append(targetDir.path)
        } else {
            Herald.declare("Linting changed files in \(product.directory)...")
            let changedFiles = try getChangedSwiftFiles(in: targetDir, repoRoot: repoRoot)

            if changedFiles.isEmpty {
                Herald.declare("No changed Swift files found.")
                return
            }

            Herald.declare("Found \(changedFiles.count) changed file(s)")

            // SwiftLint can take files directly
            args.append(contentsOf: changedFiles)
        }

        do {
            try ShellRunner.run("swiftlint", arguments: args, workingDirectory: repoRoot)
            Herald.declare("Linting complete!")
        } catch let error as ShellRunnerError {
            if case .commandFailed(_, let exitCode) = error {
                // SwiftLint returns non-zero for violations in strict mode
                if strict {
                    throw LintError.lintFailed(exitCode: exitCode)
                }
                // Otherwise just note there were violations
                Herald.warn("Linting found violations (exit code \(exitCode))")
            } else {
                throw error
            }
        }
    }

    // MARK: - Fix

    private func runFix(targetDir: URL, lintAll: Bool, repoRoot: URL) throws {
        var args: [String] = ["lint", "--fix"]

        if lintAll {
            Herald.declare("Fixing all files in \(product.directory)...")
            args.append("--path")
            args.append(targetDir.path)
        } else {
            Herald.declare("Fixing changed files in \(product.directory)...")
            let changedFiles = try getChangedSwiftFiles(in: targetDir, repoRoot: repoRoot)

            if changedFiles.isEmpty {
                Herald.declare("No changed Swift files found.")
                return
            }

            Herald.declare("Found \(changedFiles.count) changed file(s)")
            args.append(contentsOf: changedFiles)
        }

        do {
            try ShellRunner.run("swiftlint", arguments: args, workingDirectory: repoRoot)
            Herald.declare("Fix complete!")
        } catch let error as ShellRunnerError {
            if case .commandFailed(_, let exitCode) = error {
                Herald.warn("Fix completed with issues (exit code \(exitCode))")
            } else {
                throw error
            }
        }
    }

    // MARK: - Changed Files

    private func getChangedSwiftFiles(in targetDir: URL, repoRoot: URL) throws -> [String] {
        // Get files changed compared to main branch
        let output = try ShellRunner.runAndCapture(
            "git",
            arguments: ["diff", "--name-only", "main", "--", targetDir.path],
            workingDirectory: repoRoot
        )

        let files = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.hasSuffix(".swift") }

        return files
    }

    // MARK: - Tool Check

    private func requireSwiftlint() throws {
        do {
            _ = try ShellRunner.runAndCapture("which", arguments: ["swiftlint"])
        } catch {
            throw LintError.swiftlintNotFound
        }
    }
}

// MARK: - Lint Info Subcommand

struct LintInfo: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show SwiftLint information and rules."
    )

    mutating func run() throws {
        Herald.reset()

        // Check for swiftlint
        do {
            _ = try ShellRunner.runAndCapture("which", arguments: ["swiftlint"])
        } catch {
            throw LintError.swiftlintNotFound
        }

        // Show version
        Herald.declare("SwiftLint Version:")
        try ShellRunner.run("swiftlint", arguments: ["version"])

        print("")  // Blank line separator

        // Show rules
        Herald.declare("Available Rules:")
        try ShellRunner.run("swiftlint", arguments: ["rules"])
    }
}
