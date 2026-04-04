//
//  EXIFExtractorTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
import ImageIO
@testable import trippin

@Suite("EXIF GPS Parsing Tests")
struct EXIFGPSParsingTests {
    @Test("parses valid GPS coordinates")
    func validGPS() {
        let properties: [String: Any] = [
            kCGImagePropertyGPSDictionary as String: [
                kCGImagePropertyGPSLatitude as String: 35.6762,
                kCGImagePropertyGPSLatitudeRef as String: "N",
                kCGImagePropertyGPSLongitude as String: 139.6503,
                kCGImagePropertyGPSLongitudeRef as String: "E",
            ]
        ]

        let gps = PhotoKitEXIFExtractor.parseGPS(from: properties)
        #expect(gps != nil)
        #expect(abs(gps!.latitude - 35.6762) < 0.001)
        #expect(abs(gps!.longitude - 139.6503) < 0.001)
    }

    @Test("parses southern hemisphere GPS")
    func southernHemisphere() {
        let properties: [String: Any] = [
            kCGImagePropertyGPSDictionary as String: [
                kCGImagePropertyGPSLatitude as String: 33.8688,
                kCGImagePropertyGPSLatitudeRef as String: "S",
                kCGImagePropertyGPSLongitude as String: 151.2093,
                kCGImagePropertyGPSLongitudeRef as String: "E",
            ]
        ]

        let gps = PhotoKitEXIFExtractor.parseGPS(from: properties)
        #expect(gps != nil)
        #expect(gps!.latitude < 0)
        #expect(abs(gps!.latitude - (-33.8688)) < 0.001)
    }

    @Test("parses western hemisphere GPS")
    func westernHemisphere() {
        let properties: [String: Any] = [
            kCGImagePropertyGPSDictionary as String: [
                kCGImagePropertyGPSLatitude as String: 40.7128,
                kCGImagePropertyGPSLatitudeRef as String: "N",
                kCGImagePropertyGPSLongitude as String: 74.0060,
                kCGImagePropertyGPSLongitudeRef as String: "W",
            ]
        ]

        let gps = PhotoKitEXIFExtractor.parseGPS(from: properties)
        #expect(gps != nil)
        #expect(gps!.longitude < 0)
        #expect(abs(gps!.longitude - (-74.0060)) < 0.001)
    }

    @Test("returns nil for missing GPS data")
    func missingGPS() {
        let properties: [String: Any] = [:]
        let gps = PhotoKitEXIFExtractor.parseGPS(from: properties)
        #expect(gps == nil)
    }

    @Test("returns nil for incomplete GPS data")
    func incompleteGPS() {
        let properties: [String: Any] = [
            kCGImagePropertyGPSDictionary as String: [
                kCGImagePropertyGPSLatitude as String: 35.6762,
            ]
        ]
        let gps = PhotoKitEXIFExtractor.parseGPS(from: properties)
        #expect(gps == nil)
    }
}

@Suite("EXIF Camera Info Parsing Tests")
struct EXIFCameraInfoTests {
    @Test("parses full camera info")
    func fullCameraInfo() {
        let properties: [String: Any] = [
            kCGImagePropertyTIFFDictionary as String: [
                kCGImagePropertyTIFFMake as String: "Apple",
                kCGImagePropertyTIFFModel as String: "iPhone 15 Pro",
            ],
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifBodySerialNumber as String: "DNXXXXXX",
            ],
        ]

        let info = PhotoKitEXIFExtractor.parseCameraInfo(from: properties)
        #expect(info.make == "Apple")
        #expect(info.model == "iPhone 15 Pro")
        #expect(info.serial == "DNXXXXXX")
    }

    @Test("falls back to lens serial when body serial missing")
    func lensSerialFallback() {
        let properties: [String: Any] = [
            kCGImagePropertyTIFFDictionary as String: [
                kCGImagePropertyTIFFMake as String: "Canon",
                kCGImagePropertyTIFFModel as String: "EOS R5",
            ],
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifLensSerialNumber as String: "LENS123",
            ],
        ]

        let info = PhotoKitEXIFExtractor.parseCameraInfo(from: properties)
        #expect(info.serial == "LENS123")
    }

    @Test("returns nil serial when no serial available")
    func noSerial() {
        let properties: [String: Any] = [
            kCGImagePropertyTIFFDictionary as String: [
                kCGImagePropertyTIFFMake as String: "Apple",
                kCGImagePropertyTIFFModel as String: "iPhone 12",
            ],
        ]

        let info = PhotoKitEXIFExtractor.parseCameraInfo(from: properties)
        #expect(info.make == "Apple")
        #expect(info.model == "iPhone 12")
        #expect(info.serial == nil)
    }

    @Test("returns all nil for missing TIFF/EXIF data")
    func missingCameraInfo() {
        let properties: [String: Any] = [:]
        let info = PhotoKitEXIFExtractor.parseCameraInfo(from: properties)
        #expect(info.make == nil)
        #expect(info.model == nil)
        #expect(info.serial == nil)
    }
}

@Suite("EXIF Date Parsing Tests")
struct EXIFDateParsingTests {
    @Test("parses EXIF date string with timezone")
    func validDate() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let date = PhotoKitEXIFExtractor.parseDate("2024:03:15 14:30:00", timezone: tokyo)

        #expect(date != nil)

        let calendar = Calendar.current
        let components = calendar.dateComponents(in: tokyo, from: date!)
        #expect(components.year == 2024)
        #expect(components.month == 3)
        #expect(components.day == 15)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    @Test("same EXIF string produces different UTC dates for different timezones")
    func timezoneAffectsUTC() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let ny = TimeZone(identifier: "America/New_York")!

        let dateTokyo = PhotoKitEXIFExtractor.parseDate("2024:03:15 14:30:00", timezone: tokyo)!
        let dateNY = PhotoKitEXIFExtractor.parseDate("2024:03:15 14:30:00", timezone: ny)!

        #expect(dateTokyo != dateNY)
        #expect(dateNY.timeIntervalSince(dateTokyo) > 0)
    }

    @Test("returns nil for nil date string")
    func nilDate() {
        let date = PhotoKitEXIFExtractor.parseDate(nil, timezone: .current)
        #expect(date == nil)
    }

    @Test("returns nil for invalid date string")
    func invalidDate() {
        let date = PhotoKitEXIFExtractor.parseDate("not-a-date", timezone: .current)
        #expect(date == nil)
    }

    @Test("extracts raw date from properties")
    func rawDateExtraction() {
        let properties: [String: Any] = [
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifDateTimeOriginal as String: "2024:06:01 09:15:30",
            ]
        ]

        let rawDate = PhotoKitEXIFExtractor.parseRawDate(from: properties)
        #expect(rawDate == "2024:06:01 09:15:30")
    }

    @Test("returns nil raw date when EXIF missing")
    func missingRawDate() {
        let rawDate = PhotoKitEXIFExtractor.parseRawDate(from: [:])
        #expect(rawDate == nil)
    }
}

@Suite("EXIF Timezone Tests")
struct EXIFTimezoneTests {
    @Test("Tokyo longitude resolves to ~UTC+9")
    func tokyoTimezone() {
        let tz = PhotoKitEXIFExtractor.timezoneFromLongitude(139.6503)
        #expect(tz.secondsFromGMT() == 9 * 3600)
    }

    @Test("New York longitude resolves to ~UTC-5")
    func newYorkTimezone() {
        let tz = PhotoKitEXIFExtractor.timezoneFromLongitude(-74.0060)
        #expect(tz.secondsFromGMT() == -5 * 3600)
    }

    @Test("nil longitude returns current timezone")
    func nilLongitude() {
        let tz = PhotoKitEXIFExtractor.timezoneFromLongitude(nil)
        #expect(tz.identifier == TimeZone.current.identifier)
    }

    @Test("zero longitude returns UTC")
    func zeroLongitude() {
        let tz = PhotoKitEXIFExtractor.timezoneFromLongitude(0.0)
        #expect(tz.secondsFromGMT() == 0)
    }
}
