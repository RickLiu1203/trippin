//
//  EXIFExtractor.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import CoreLocation
import Foundation
import ImageIO
import Photos

struct ExtractedPhotoData: Sendable {
    let localAssetId: String
    let latitude: Double?
    let longitude: Double?
    let takenAt: Date
    let cameraMake: String?
    let cameraModel: String?
    let cameraSerial: String?
}

enum EXIFError: Error, LocalizedError {
    case noImageData

    var errorDescription: String? {
        switch self {
        case .noImageData: "Failed to load image data"
        }
    }
}

protocol EXIFExtractorService: Sendable {
    func extractMetadata(from asset: PHAsset) async throws -> ExtractedPhotoData
    func extractBatch(from assets: [PHAsset], maxConcurrent: Int) async -> [ExtractedPhotoData]
}

final class PhotoKitEXIFExtractor: EXIFExtractorService, @unchecked Sendable {
    func extractMetadata(from asset: PHAsset) async throws -> ExtractedPhotoData {
        let data = try await requestImageData(for: asset)
        let properties = Self.extractProperties(from: data)

        let gps = Self.parseGPS(from: properties)
        let cameraInfo = Self.parseCameraInfo(from: properties)
        let rawDate = Self.parseRawDate(from: properties)

        var timezone = TimeZone.current
        if let gps {
            timezone = await Self.resolveTimezone(latitude: gps.latitude, longitude: gps.longitude)
        }

        let takenAt = Self.parseDate(rawDate, timezone: timezone) ?? asset.creationDate ?? Date()

        return ExtractedPhotoData(
            localAssetId: asset.localIdentifier,
            latitude: gps?.latitude,
            longitude: gps?.longitude,
            takenAt: takenAt,
            cameraMake: cameraInfo.make,
            cameraModel: cameraInfo.model,
            cameraSerial: cameraInfo.serial
        )
    }

    func extractBatch(from assets: [PHAsset], maxConcurrent: Int = 5) async -> [ExtractedPhotoData] {
        await withTaskGroup(of: ExtractedPhotoData?.self) { group in
            var results: [ExtractedPhotoData] = []
            var iterator = assets.makeIterator()

            for _ in 0..<min(maxConcurrent, assets.count) {
                if let asset = iterator.next() {
                    group.addTask { try? await self.extractMetadata(from: asset) }
                }
            }

            for await result in group {
                if let result { results.append(result) }
                if let asset = iterator.next() {
                    group.addTask { try? await self.extractMetadata(from: asset) }
                }
            }

            return results
        }
    }

    private func requestImageData(for asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: EXIFError.noImageData)
                }
            }
        }
    }

    static func extractProperties(from data: Data) -> [String: Any] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        else { return [:] }
        return properties
    }

    static func parseGPS(from properties: [String: Any]) -> (latitude: Double, longitude: Double)? {
        guard let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String
        else { return nil }

        let latitude = latRef == "S" ? -lat : lat
        let longitude = lonRef == "W" ? -lon : lon
        return (latitude, longitude)
    }

    static func parseCameraInfo(from properties: [String: Any]) -> (make: String?, model: String?, serial: String?) {
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]

        let make = tiff?[kCGImagePropertyTIFFMake as String] as? String
        let model = tiff?[kCGImagePropertyTIFFModel as String] as? String
        let serial = exif?[kCGImagePropertyExifBodySerialNumber as String] as? String
            ?? exif?[kCGImagePropertyExifLensSerialNumber as String] as? String

        return (make, model, serial)
    }

    static func parseRawDate(from properties: [String: Any]) -> String? {
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        return exif?[kCGImagePropertyExifDateTimeOriginal as String] as? String
    }

    static func parseDate(_ rawDate: String?, timezone: TimeZone) -> Date? {
        guard let rawDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = timezone
        return formatter.date(from: rawDate)
    }

    static func resolveTimezone(latitude: Double, longitude: Double) async -> TimeZone {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.timeZone ?? .current
        } catch {
            let offsetHours = Int(round(longitude / 15.0))
            return TimeZone(secondsFromGMT: offsetHours * 3600) ?? .current
        }
    }
}
