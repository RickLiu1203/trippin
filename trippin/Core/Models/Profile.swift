//
//  Profile.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct Profile: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var displayName: String
    var avatarUrl: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
