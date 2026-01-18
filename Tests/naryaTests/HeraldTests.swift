// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing
@testable import narya

@Suite("Herald Tests", .serialized)
struct HeraldTests {

    // MARK: - Test Helpers

    /// Captures stdout output from a closure
    private func captureOutput(_ block: () -> Void) -> String {
        let pipe = Pipe()
        let originalStdout = dup(STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        block()

        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
        pipe.fileHandleForWriting.closeFile()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - First Line Tests

    @Test("First line uses ring prefix")
    func firstLineUsesRingPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Hello")
        }
        #expect(output == "💍 Hello\n")
    }

    @Test("First line with asError uses ring and error prefix")
    func firstLineWithErrorUsesRingAndErrorPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Error occurred", asError: true)
        }
        #expect(output == "💍 💥 Error occurred\n")
    }

    @Test("First line with asConclusion uses ring prefix")
    func firstLineWithConclusionUsesRingPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Done!", asConclusion: true)
        }
        #expect(output == "💍 Done!\n")
    }

    @Test("First line with asError and asConclusion uses ring and error prefix")
    func firstLineWithErrorAndConclusionUsesRingAndErrorPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Failed!", asError: true, asConclusion: true)
        }
        #expect(output == "💍 💥 Failed!\n")
    }

    // MARK: - Subsequent Line Tests

    @Test("Subsequent line uses continuation prefix")
    func subsequentLineUsesContinuationPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Second")
        }
        #expect(output == "💍 First\n▒ Second\n")
    }

    @Test("Subsequent line with asError uses continuation and error prefix")
    func subsequentLineWithErrorUsesContinuationAndErrorPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Error occurred", asError: true)
        }
        #expect(output == "💍 First\n▒ 💥 Error occurred\n")
    }

    @Test("Subsequent line with asConclusion uses ring prefix")
    func subsequentLineWithConclusionUsesRingPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Done!", asConclusion: true)
        }
        #expect(output == "💍 First\n💍 Done!\n")
    }

    @Test("Subsequent line with asError and asConclusion uses ring and error prefix")
    func subsequentLineWithErrorAndConclusionUsesRingAndErrorPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Failed!", asError: true, asConclusion: true)
        }
        #expect(output == "💍 First\n💍 💥 Failed!\n")
    }

    // MARK: - Multi-line Message Tests

    @Test("Multi-line message on first call uses ring then sub-continuation")
    func multiLineMessageFirstCallUsesRingThenSubContinuation() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Line one\nLine two\nLine three")
        }
        #expect(output == "💍 Line one\n▒ ▒ Line two\n▒ ▒ Line three\n")
    }

    @Test("Multi-line message on subsequent call uses continuation then sub-continuation")
    func multiLineMessageSubsequentCallUsesContinuationThenSubContinuation() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Line one\nLine two")
        }
        #expect(output == "💍 First\n▒ Line one\n▒ ▒ Line two\n")
    }

    @Test("Multi-line error message uses error prefix only on first line")
    func multiLineErrorMessageUsesErrorPrefixOnlyOnFirstLine() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Error line one\nError line two", asError: true)
        }
        #expect(output == "💍 💥 Error line one\n▒ ▒ Error line two\n")
    }

    @Test("Multi-line conclusion message uses ring prefix only on first line")
    func multiLineConclusionMessageUsesRingPrefixOnlyOnFirstLine() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Conclusion line one\nConclusion line two", asConclusion: true)
        }
        #expect(output == "💍 First\n💍 Conclusion line one\n▒ ▒ Conclusion line two\n")
    }

    // MARK: - Reset Tests

    @Test("Reset restores first line behavior")
    func resetRestoresFirstLineBehavior() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Second")
            Herald.reset()
            Herald.declare("After reset")
        }
        #expect(output == "💍 First\n▒ Second\n💍 After reset\n")
    }

    @Test("Multiple resets work correctly")
    func multipleResetsWorkCorrectly() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("A")
            Herald.reset()
            Herald.declare("B")
            Herald.reset()
            Herald.declare("C")
        }
        #expect(output == "💍 A\n💍 B\n💍 C\n")
    }

    // MARK: - State Behavior Tests

    @Test("asConclusion does not reset state")
    func asConclusionDoesNotResetState() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Conclusion", asConclusion: true)
            Herald.declare("After conclusion")
        }
        // After conclusion, state is still "not first line", so next line uses ▒
        #expect(output == "💍 First\n💍 Conclusion\n▒ After conclusion\n")
    }

    @Test("asError does not affect state")
    func asErrorDoesNotAffectState() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("First")
            Herald.declare("Error", asError: true)
            Herald.declare("After error")
        }
        #expect(output == "💍 First\n▒ 💥 Error\n▒ After error\n")
    }

    // MARK: - Edge Cases

    @Test("Empty message still outputs prefix")
    func emptyMessageStillOutputsPrefix() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("")
        }
        #expect(output == "💍 \n")
    }

    @Test("Message with only newlines")
    func messageWithOnlyNewlines() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("\n\n")
        }
        // Three empty lines: first gets 💍, subsequent get ▒ ▒
        #expect(output == "💍 \n▒ ▒ \n▒ ▒ \n")
    }

    @Test("Long sequence of calls")
    func longSequenceOfCalls() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("1")
            Herald.declare("2")
            Herald.declare("3")
            Herald.declare("4")
            Herald.declare("5")
        }
        #expect(output == "💍 1\n▒ 2\n▒ 3\n▒ 4\n▒ 5\n")
    }

    @Test("Mixed normal and conclusion calls")
    func mixedNormalAndConclusionCalls() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Starting...")
            Herald.declare("Processing...")
            Herald.declare("Done!", asConclusion: true)
        }
        #expect(output == "💍 Starting...\n▒ Processing...\n💍 Done!\n")
    }

    @Test("Interleaved errors and normal messages")
    func interleavedErrorsAndNormalMessages() {
        Herald.reset()
        let output = captureOutput {
            Herald.declare("Step 1")
            Herald.declare("Warning!", asError: true)
            Herald.declare("Step 2")
            Herald.declare("Error!", asError: true)
            Herald.declare("Completed with errors", asError: true, asConclusion: true)
        }
        #expect(output == "💍 Step 1\n▒ 💥 Warning!\n▒ Step 2\n▒ 💥 Error!\n💍 💥 Completed with errors\n")
    }
}
