//
//  PhotoMetadata.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct PhotoMetadata: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let tripId: UUID
    var memberId: UUID?
    let localAssetId: String
    var latitude: Double?
    var longitude: Double?
    var takenAt: Date
    var cameraMake: String?
    var cameraModel: String?
    var cameraSerial: String?
    var category: PhotoCategory?
    var confidence: Double?
    var dayIndex: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case memberId = "member_id"
        case localAssetId = "local_asset_id"
        case latitude
        case longitude
        case takenAt = "taken_at"
        case cameraMake = "camera_make"
        case cameraModel = "camera_model"
        case cameraSerial = "camera_serial"
        case category
        case confidence
        case dayIndex = "day_index"
    }
}
