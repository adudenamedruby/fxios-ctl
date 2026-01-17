// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing
@testable import narya

@Suite("DeviceShorthand Tests", .serialized)
struct DeviceShorthandTests {

    // MARK: - iPhone Shorthand Derivation Tests

    @Test("iPhone base model derives shorthand")
    func iphoneBaseModel() {
        #expect(DeviceShorthand.shorthand(for: "iPhone 17") == "17")
        #expect(DeviceShorthand.shorthand(for: "iPhone 16") == "16")
        #expect(DeviceShorthand.shorthand(for: "iPhone 15") == "15")
    }

    @Test("iPhone Pro derives shorthand")
    func iphonePro() {
        #expect(DeviceShorthand.shorthand(for: "iPhone 17 Pro") == "17pro")
        #expect(DeviceShorthand.shorthand(for: "iPhone 16 Pro") == "16pro")
    }

    @Test("iPhone Pro Max derives shorthand")
    func iphoneProMax() {
        #expect(DeviceShorthand.shorthand(for: "iPhone 17 Pro Max") == "17max")
        #expect(DeviceShorthand.shorthand(for: "iPhone 16 Pro Max") == "16max")
    }

    @Test("iPhone Plus derives shorthand")
    func iphonePlus() {
        #expect(DeviceShorthand.shorthand(for: "iPhone 17 Plus") == "17plus")
        #expect(DeviceShorthand.shorthand(for: "iPhone 16 Plus") == "16plus")
    }

    @Test("iPhone e variant derives shorthand")
    func iphoneEVariant() {
        #expect(DeviceShorthand.shorthand(for: "iPhone 16e") == "16e")
    }

    @Test("iPhone SE derives shorthand")
    func iphoneSE() {
        #expect(DeviceShorthand.shorthand(for: "iPhone SE") == "se")
        #expect(DeviceShorthand.shorthand(for: "iPhone SE (3rd generation)") == "se")
    }

    @Test("iPhone Air derives shorthand")
    func iphoneAir() {
        #expect(DeviceShorthand.shorthand(for: "iPhone Air") == "air")
    }

    // MARK: - iPad Air/Pro Shorthand Derivation Tests

    @Test("iPad Air with whole inch size derives shorthand")
    func ipadAirWholeInch() {
        #expect(DeviceShorthand.shorthand(for: "iPad Air 11-inch") == "air11")
        #expect(DeviceShorthand.shorthand(for: "iPad Air 13-inch") == "air13")
        #expect(DeviceShorthand.shorthand(for: "iPad Air 11-inch (M2)") == "air11")
    }

    @Test("iPad Pro with whole inch size derives shorthand")
    func ipadProWholeInch() {
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 11-inch") == "pro11")
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 13-inch") == "pro13")
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 11-inch (M4)") == "pro11")
    }

    @Test("iPad Pro 12.9-inch derives guessable shorthand")
    func ipadPro129Inch() {
        // 12.9-inch should derive to guessable "13"
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 12.9-inch") == "pro13")
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 12.9-inch (6th generation)") == "pro13")
    }

    @Test("iPad with 10.x-inch sizes derives guessable shorthand")
    func ipadTenInchVariants() {
        // All 10.x sizes should derive to guessable "10"
        #expect(DeviceShorthand.shorthand(for: "iPad Air 10.9-inch") == "air10")
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 10.5-inch") == "pro10")
    }

    // MARK: - iPad mini Shorthand Derivation Tests

    @Test("iPad mini without suffix derives shorthand")
    func ipadMiniPlain() {
        #expect(DeviceShorthand.shorthand(for: "iPad mini") == "mini")
    }

    @Test("iPad mini with generation derives shorthand")
    func ipadMiniGeneration() {
        #expect(DeviceShorthand.shorthand(for: "iPad mini (6th generation)") == "mini6g")
        #expect(DeviceShorthand.shorthand(for: "iPad mini (7th generation)") == "mini7g")
        // Test ordinal handling
        #expect(DeviceShorthand.shorthand(for: "iPad mini (1st generation)") == "mini1g")
        #expect(DeviceShorthand.shorthand(for: "iPad mini (2nd generation)") == "mini2g")
        #expect(DeviceShorthand.shorthand(for: "iPad mini (3rd generation)") == "mini3g")
    }

    @Test("iPad mini with chip derives shorthand")
    func ipadMiniChip() {
        #expect(DeviceShorthand.shorthand(for: "iPad mini (A17 Pro)") == "miniA17")
        #expect(DeviceShorthand.shorthand(for: "iPad mini (A15)") == "miniA15")
    }

    // MARK: - iPad Generation Shorthand Derivation Tests

    @Test("iPad with generation derives shorthand")
    func ipadGeneration() {
        #expect(DeviceShorthand.shorthand(for: "iPad (10th generation)") == "pad10g")
        #expect(DeviceShorthand.shorthand(for: "iPad (9th generation)") == "pad9g")
        // Test ordinal handling
        #expect(DeviceShorthand.shorthand(for: "iPad (1st generation)") == "pad1g")
        #expect(DeviceShorthand.shorthand(for: "iPad (2nd generation)") == "pad2g")
        #expect(DeviceShorthand.shorthand(for: "iPad (3rd generation)") == "pad3g")
    }

    @Test("iPad with chip derives shorthand")
    func ipadChip() {
        #expect(DeviceShorthand.shorthand(for: "iPad (A16)") == "padA16")
        #expect(DeviceShorthand.shorthand(for: "iPad (A14)") == "padA14")
    }

    // MARK: - Devices Without Shorthands

    @Test("Devices that don't fit patterns return nil")
    func devicesWithoutShorthands() {
        // Old iPad naming with parens around size
        #expect(DeviceShorthand.shorthand(for: "iPad Pro (11-inch) (4th generation)") == nil)
        // Apple Watch
        #expect(DeviceShorthand.shorthand(for: "Apple Watch Series 9") == nil)
        // Apple TV
        #expect(DeviceShorthand.shorthand(for: "Apple TV 4K") == nil)
    }

    // MARK: - Error Description Tests

    @Test("Invalid shorthand error includes examples")
    func invalidShorthandError() {
        let error = DeviceShorthandError.invalidShorthand(shorthand: "xyz")
        let description = error.description
        #expect(description.contains("xyz"))
        #expect(description.contains("17pro"))
        #expect(description.contains("mini6g"))
        #expect(description.contains("pro13"))
    }

    @Test("Simulator not found error includes available simulators")
    func simulatorNotFoundError() {
        let error = DeviceShorthandError.simulatorNotFound(
            shorthand: "99pro",
            type: .phone,
            available: ["iPhone 17 (iOS 18.2)", "iPhone 16 (iOS 18.2)"]
        )
        let description = error.description
        #expect(description.contains("99pro"))
        #expect(description.contains("iPhone 17"))
    }

    // MARK: - Guessable Size Tests

    @Test("deriveGuessableSize converts fractional to whole")
    func deriveGuessableSizeConversion() {
        // Test via full device name derivation
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 12.9-inch") == "pro13")
        #expect(DeviceShorthand.shorthand(for: "iPad Air 10.9-inch") == "air10")
        #expect(DeviceShorthand.shorthand(for: "iPad Pro 10.5-inch") == "pro10")
    }
}
