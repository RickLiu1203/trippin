//
//  DeviceMappingService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Supabase

@MainActor
protocol DeviceMappingService: Sendable {
    func fetchMapping(tripId: UUID, cameraIdentifier: String) async throws -> DeviceMapping?
    func createMapping(tripId: UUID, cameraIdentifier: String, memberId: UUID) async throws -> DeviceMapping
}

final class SupabaseDeviceMappingService: DeviceMappingService {
    func fetchMapping(tripId: UUID, cameraIdentifier: String) async throws -> DeviceMapping? {
        let results: [DeviceMapping] = try await supabase
            .from("device_mappings")
            .select()
            .eq("trip_id", value: tripId.uuidString)
            .eq("camera_identifier", value: cameraIdentifier)
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func createMapping(tripId: UUID, cameraIdentifier: String, memberId: UUID) async throws -> DeviceMapping {
        try await supabase
            .from("device_mappings")
            .insert(CreateDeviceMappingParams(
                tripId: tripId,
                cameraIdentifier: cameraIdentifier,
                memberId: memberId
            ))
            .select()
            .single()
            .execute()
            .value
    }
}

private struct CreateDeviceMappingParams: Encodable {
    let tripId: UUID
    let cameraIdentifier: String
    let memberId: UUID

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case cameraIdentifier = "camera_identifier"
        case memberId = "member_id"
    }
}
