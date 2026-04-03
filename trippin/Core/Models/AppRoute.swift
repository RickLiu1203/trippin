//
//  AppRoute.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

enum AppTab: Int, Sendable {
    case trips
    case map
    case photos
    case profile
}

enum AppRoute: Hashable, Sendable {
    // Trips
    case tripDetail(tripId: UUID)
    case createTrip
    case editTrip(tripId: UUID)
    case linkAlbum(tripId: UUID)
    case dayView(tripId: UUID, dayIndex: Int)
    case eventDetail(clusterId: UUID)
    case shareTrip(tripId: UUID)

    // Map
    case clusterDetail(clusterId: UUID)

    // Photos
    case photoDetail(photoId: UUID)
    case photoFilter(tripId: UUID)
    case photoSearch(tripId: UUID)

    // Profile
    case settings
    case account

    // Processing
    case placeReview(tripId: UUID)
    case deviceClaim(tripId: UUID)

    // Auth
    case guestJoin(shareCode: String)
}
