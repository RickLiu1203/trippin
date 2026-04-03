//
//  Trip.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct Trip: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let ownerId: UUID
    var name: String
    let shareCode: String
    var albumIdentifier: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case shareCode = "share_code"
        case albumIdentifier = "album_identifier"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
