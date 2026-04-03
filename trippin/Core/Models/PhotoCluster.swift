//
//  PhotoCluster.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct PhotoCluster: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let tripId: UUID
    var centroidLat: Double
    var centroidLon: Double
    var startTime: Date
    var endTime: Date
    var dayIndex: Int
    var clusterOrder: Int
    var placeId: UUID?
    var photoCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case centroidLat = "centroid_lat"
        case centroidLon = "centroid_lon"
        case startTime = "start_time"
        case endTime = "end_time"
        case dayIndex = "day_index"
        case clusterOrder = "cluster_order"
        case placeId = "place_id"
        case photoCount = "photo_count"
    }
}
