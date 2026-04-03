//
//  Place.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct Place: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var googlePlaceId: String?
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var category: String?
    var source: PlaceSource

    enum CodingKeys: String, CodingKey {
        case id
        case googlePlaceId = "google_place_id"
        case name
        case address
        case latitude
        case longitude
        case category
        case source
    }
}
