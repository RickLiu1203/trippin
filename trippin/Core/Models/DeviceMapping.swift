//
//  DeviceMapping.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct DeviceMapping: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let tripId: UUID
    let cameraIdentifier: String
    let memberId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case cameraIdentifier = "camera_identifier"
        case memberId = "member_id"
    }
}
