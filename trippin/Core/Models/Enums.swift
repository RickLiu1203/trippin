//
//  Enums.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

enum ProcessingStatus: String, Codable, Sendable {
    case idle
    case processing
    case complete
    case error
}

enum PhotoCategory: String, Codable, Sendable, CaseIterable {
    case food
    case scenery
    case landmark
    case activity
}

enum MemberRole: String, Codable, Sendable {
    case owner
    case member
    case guest
}

enum PlaceSource: String, Codable, Sendable {
    case google
    case userInput = "user_input"
}
