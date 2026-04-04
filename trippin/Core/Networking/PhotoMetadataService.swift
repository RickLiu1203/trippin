//
//  PhotoMetadataService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Supabase

@MainActor
protocol PhotoMetadataService: Sendable {
    func fetchExistingAssetIds(tripId: UUID) async throws -> Set<String>
    func insertBatch(_ metadata: [InsertPhotoMetadataParams]) async throws
}

struct InsertPhotoMetadataParams: Encodable, Sendable {
    let tripId: UUID
    let memberId: UUID?
    let localAssetId: String
    let latitude: Double?
    let longitude: Double?
    let takenAt: Date
    let cameraMake: String?
    let cameraModel: String?
    let cameraSerial: String?
    let category: String?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
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
    }
}

final class SupabasePhotoMetadataService: PhotoMetadataService {
    func fetchExistingAssetIds(tripId: UUID) async throws -> Set<String> {
        let rows: [AssetIdRow] = try await supabase
            .from("photo_metadata")
            .select("local_asset_id")
            .eq("trip_id", value: tripId.uuidString)
            .execute()
            .value
        return Set(rows.map(\.localAssetId))
    }

    func insertBatch(_ metadata: [InsertPhotoMetadataParams]) async throws {
        guard !metadata.isEmpty else { return }
        try await supabase
            .from("photo_metadata")
            .insert(metadata)
            .execute()
    }
}

private struct AssetIdRow: Decodable {
    let localAssetId: String

    enum CodingKeys: String, CodingKey {
        case localAssetId = "local_asset_id"
    }
}
