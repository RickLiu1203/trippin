//
//  TripMember.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct TripMember: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let tripId: UUID
    let userId: UUID
    var displayName: String
    var emoji: String
    var color: String
    var role: MemberRole
    var cameraIdentifier: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case userId = "user_id"
        case displayName = "display_name"
        case emoji
        case color
        case role
        case cameraIdentifier = "camera_identifier"
        case createdAt = "created_at"
    }
}
