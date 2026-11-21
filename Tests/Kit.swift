//
//  Kit.swift
//  Tests
//
//  Created by Serhiy Mytrovtsiy on 04/07/2026.
//  Using Swift 6.0.
//  Running on macOS 26.5.
//
//  Copyright © 2026 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import XCTest
import Kit

class KitTests: XCTestCase {
    private let gibibyte: Int64 = 1 << 30

    func testCompactMenuBarUsesFixedWidthWholeGigabytes() {
        XCTAssertEqual(CompactMenuBar.disk(freeBytes: 43_999_999_999).text, "043")
        XCTAssertEqual(CompactMenuBar.disk(freeBytes: 100_000_000_000).text, "100")
        XCTAssertEqual(CompactMenuBar.disk(freeBytes: 1_000_000_000_000).text, "999")
        XCTAssertEqual(CompactMenuBar.memory(freeBytes: 5 * gibibyte - 1).text, "04")
        XCTAssertEqual(CompactMenuBar.memory(freeBytes: 0).text, "00")
        XCTAssertEqual(CompactMenuBar.memory(freeBytes: 100 * gibibyte).text, "99")
    }

    @MainActor
    func testCompactMenuBarTextKeepsItsWidthAcrossDigitAndColorChanges() {
        let canvas = NSImage(size: NSSize(width: 100, height: 28))
        canvas.lockFocus()
        defer { canvas.unlockFocus() }

        for (normal, critical) in [("111", "008"), ("11", "00")] {
            let view = TextWidget(title: "Metrics")
            view.setValue(normal, tone: .normal)
            view.draw(view.bounds)
            let normalWidth = view.shadowSize.width
            view.setValue(critical, tone: .red)
            view.draw(view.bounds)
            XCTAssertEqual(view.shadowSize.width, normalWidth)
        }
    }

    func testCompactMenuBarDiskColorsUseStrictByteThresholds() {
        XCTAssertEqual(CompactMenuBar.disk(freeBytes: 40_000_000_000).tone, .normal)
        XCTAssertEqual(CompactMenuBar.disk(freeBytes: 39_999_999_999).tone, .yellow)
        XCTAssertEqual(CompactMenuBar.disk(freeBytes: 15_000_000_000).tone, .yellow)
        XCTAssertEqual(CompactMenuBar.disk(freeBytes: 14_999_999_999).tone, .red)
    }

    func testCompactMenuBarRAMColorsUseInclusiveByteThresholds() {
        XCTAssertEqual(CompactMenuBar.memory(freeBytes: 2 * gibibyte + 1).tone, .normal)
        XCTAssertEqual(CompactMenuBar.memory(freeBytes: 2 * gibibyte).tone, .orange)
        XCTAssertEqual(CompactMenuBar.memory(freeBytes: gibibyte + 1).tone, .orange)
        XCTAssertEqual(CompactMenuBar.memory(freeBytes: gibibyte).tone, .red)
    }

    func testCompactMenuBarBatteryOnlyShowsWhenUnpluggedBelowHalf() {
        XCTAssertTrue(CompactMenuBar.showsBattery(level: 0.49, onBatteryPower: true, isCharging: false))
        XCTAssertTrue(CompactMenuBar.showsBattery(level: 0, onBatteryPower: true, isCharging: false))
        XCTAssertFalse(CompactMenuBar.showsBattery(level: 0.50, onBatteryPower: true, isCharging: false))
        XCTAssertFalse(CompactMenuBar.showsBattery(level: 0.49, onBatteryPower: false, isCharging: false))
        XCTAssertFalse(CompactMenuBar.showsBattery(level: 0.49, onBatteryPower: true, isCharging: true))
    }

    func testCompactMenuBarAlertColorsContrastWithLightAndDarkBackgrounds() throws {
        let tones: [CompactMenuBar.Tone] = [.yellow, .orange, .red]
        for tone in tones {
            for (dark, background) in [(false, 0.95), (true, 0.1)] {
                let foreground = try XCTUnwrap(tone.color(dark: dark).usingColorSpace(.sRGB))
                let foregroundLuminance = 0.2126 * linear(foreground.redComponent)
                    + 0.7152 * linear(foreground.greenComponent)
                    + 0.0722 * linear(foreground.blueComponent)
                let backgroundLuminance = linear(background)
                let contrast = (max(foregroundLuminance, backgroundLuminance) + 0.05)
                    / (min(foregroundLuminance, backgroundLuminance) + 0.05)
                XCTAssertGreaterThanOrEqual(contrast, 4.5, "\(tone), dark: \(dark)")
            }
        }
    }

    private func linear(_ component: CGFloat) -> CGFloat {
        component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }

    func testIsNewestVersion_release() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.1", latestVersion: "v2.11.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.12.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.12.0", latestVersion: "v2.11.5"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v3.0.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v3.0.0", latestVersion: "v2.99.99"))
    }
    
    func testIsNewestVersion_beta() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0-beta1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta2", latestVersion: "v2.11.0-beta1"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0-beta2"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.10.9"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.1-beta1"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.1-beta1"))
    }
    
    func testIsNewestVersion_malformed() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v3", latestVersion: "v3.0.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v3", latestVersion: "v3.0.1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v3.0", latestVersion: "v3.0.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "", latestVersion: ""))
    }
    
    func testUnitsGetReadableSpeed_byte() throws {
        XCTAssertEqual(Units(bytes: 0).getReadableSpeed(base: .byte), "0 KB/s")
        XCTAssertEqual(Units(bytes: 999).getReadableSpeed(base: .byte), "0 KB/s")
        XCTAssertEqual(Units(bytes: 1_000).getReadableSpeed(base: .byte), "1 KB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte), "500 KB/s")
        XCTAssertEqual(Units(bytes: 2_500_000).getReadableSpeed(base: .byte), "2.5 MB/s")
        XCTAssertEqual(Units(bytes: 150_000_000).getReadableSpeed(base: .byte), "150 MB/s")
        XCTAssertEqual(Units(bytes: 2_000_000_000).getReadableSpeed(base: .byte), "2.0 GB/s")
        XCTAssertEqual(Units(bytes: 2_000_000_000_000).getReadableSpeed(base: .byte), "2.0 TB/s")
        XCTAssertEqual(Units(bytes: -5).getReadableSpeed(base: .byte), "0 KB/s")
    }
    
    func testUnitsGetReadableSpeed_bit() throws {
        XCTAssertEqual(Units(bytes: 100).getReadableSpeed(base: .bit), "0 Kb/s")
        XCTAssertEqual(Units(bytes: 50_000).getReadableSpeed(base: .bit), "400 Kb/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .bit), "4.0 Mb/s")
        XCTAssertEqual(Units(bytes: 200_000_000).getReadableSpeed(base: .bit), "1.6 Gb/s")
        XCTAssertEqual(Units(bytes: 200_000_000_000).getReadableSpeed(base: .bit), "1.6 Tb/s")
    }
    
    func testUnitsGetReadableSpeed_fixedUnit() throws {
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte, unit: "KB"), "500.00 KB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte, unit: "MB"), "0.50 MB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .bit, unit: "MB"), "4.00 Mb/s")
        XCTAssertEqual(Units(bytes: 1_250_000_000).getReadableSpeed(base: .byte, unit: "GB"), "1.25 GB/s")
        XCTAssertEqual(Units(bytes: 1_250_000_000_000).getReadableSpeed(base: .byte, unit: "TB"), "1.25 TB/s")
    }
    
    func testUnitsGetReadableSpeed_fixedUnitZero() throws {
        for unit in ["KB", "MB", "GB", "TB"] {
            for base in [DataSizeBase.byte, .bit] {
                XCTAssertEqual(Units(bytes: 0).getReadableSpeed(base: base, unit: unit, omitUnits: true), "0.00")
                XCTAssertEqual(Units(bytes: 1).getReadableSpeed(base: base, unit: unit, omitUnits: true), base == .bit && unit == "KB" ? "0.01" : "0.00")
            }
        }
    }
    
    func testUnitsGetReadableSpeed_fixedUnitPrecision() throws {
        XCTAssertEqual(Units(bytes: 4_900).getReadableSpeed(unit: "MB"), "0.00 MB/s")
        XCTAssertEqual(Units(bytes: 5_100).getReadableSpeed(unit: "MB"), "0.01 MB/s")
        XCTAssertEqual(Units(bytes: 10_000).getReadableSpeed(unit: "MB"), "0.01 MB/s")
        XCTAssertEqual(Units(bytes: 350_000).getReadableSpeed(unit: "MB"), "0.35 MB/s")
        XCTAssertEqual(Units(bytes: 1_260_000).getReadableSpeed(unit: "MB"), "1.26 MB/s")
        XCTAssertEqual(Units(bytes: 9_999_000).getReadableSpeed(unit: "MB"), "10.00 MB/s")
        XCTAssertEqual(Units(bytes: 12_340_000).getReadableSpeed(unit: "MB"), "12.34 MB/s")
        XCTAssertEqual(Units(bytes: 99_999_000).getReadableSpeed(unit: "MB"), "100.00 MB/s")
        XCTAssertEqual(Units(bytes: 123_450_000).getReadableSpeed(unit: "MB"), "123.45 MB/s")
        XCTAssertEqual(Units(bytes: 1_000_000_000).getReadableSpeed(unit: "KB"), "1000000.00 KB/s")
    }
}
