//
//  TripService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Supabase

enum TripServiceError: Error {
    case notAuthenticated
}

@MainActor
protocol TripService: Sendable {
    func fetchTrips() async throws -> [Trip]
    func createTrip(name: String) async throws -> Trip
    func updateTrip(id: UUID, name: String) async throws -> Trip
    func deleteTrip(id: UUID) async throws
    func fetchTrip(id: UUID) async throws -> Trip
    func updateTripAlbum(id: UUID, albumIdentifier: String) async throws -> Trip
    func fetchMembers(tripId: UUID) async throws -> [TripMember]
    func fetchPhotoCount(tripId: UUID) async throws -> Int
}

final class SupabaseTripService: TripService {
    func fetchTrips() async throws -> [Trip] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw TripServiceError.notAuthenticated
        }

        let memberRows: [TripIdRow] = try await supabase
            .from("trip_members")
            .select("trip_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let tripIds = memberRows.map(\.tripId)
        guard !tripIds.isEmpty else { return [] }

        return try await supabase
            .from("trips")
            .select()
            .in("id", values: tripIds.map(\.uuidString))
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func createTrip(name: String) async throws -> Trip {
        guard let user = supabase.auth.currentUser else {
            throw TripServiceError.notAuthenticated
        }

        let trips: [Trip] = try await supabase
            .from("trips")
            .insert(CreateTripParams(ownerId: user.id, name: name))
            .select()
            .execute()
            .value
        guard let trip = trips.first else {
            throw TripServiceError.notAuthenticated
        }

        let profiles: [Profile] = (try? await supabase
            .from("profiles")
            .select()
            .eq("id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value) ?? []

        _ = try await supabase
            .from("trip_members")
            .insert(CreateMemberParams(
                tripId: trip.id,
                userId: user.id,
                displayName: profiles.first?.displayName ?? "",
                emoji: "\u{1F338}",
                color: "#FF6B6B",
                role: "owner"
            ))
            .execute()

        return trip
    }

    func updateTrip(id: UUID, name: String) async throws -> Trip {
        let results: [Trip] = try await supabase
            .from("trips")
            .update(UpdateTripParams(name: name))
            .eq("id", value: id.uuidString)
            .select()
            .execute()
            .value
        guard let trip = results.first else {
            throw TripServiceError.notAuthenticated
        }
        return trip
    }

    func deleteTrip(id: UUID) async throws {
        try await supabase
            .from("trips")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func fetchTrip(id: UUID) async throws -> Trip {
        let results: [Trip] = try await supabase
            .from("trips")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        guard let trip = results.first else {
            throw TripServiceError.notAuthenticated
        }
        return trip
    }

    func updateTripAlbum(id: UUID, albumIdentifier: String) async throws -> Trip {
        let results: [Trip] = try await supabase
            .from("trips")
            .update(UpdateAlbumParams(albumIdentifier: albumIdentifier))
            .eq("id", value: id.uuidString)
            .select()
            .execute()
            .value
        guard let trip = results.first else {
            throw TripServiceError.notAuthenticated
        }
        return trip
    }

    func fetchMembers(tripId: UUID) async throws -> [TripMember] {
        try await supabase
            .from("trip_members")
            .select()
            .eq("trip_id", value: tripId.uuidString)
            .execute()
            .value
    }

    func fetchPhotoCount(tripId: UUID) async throws -> Int {
        try await supabase
            .from("photo_metadata")
            .select("*", head: true, count: .exact)
            .eq("trip_id", value: tripId.uuidString)
            .execute()
            .count ?? 0
    }
}

private struct TripIdRow: Decodable {
    let tripId: UUID

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
    }
}

private struct CreateTripParams: Encodable {
    let ownerId: UUID
    let name: String

    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case name
    }
}

private struct CreateMemberParams: Encodable {
    let tripId: UUID
    let userId: UUID
    let displayName: String
    let emoji: String
    let color: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case userId = "user_id"
        case displayName = "display_name"
        case emoji, color, role
    }
}

private struct UpdateTripParams: Encodable {
    let name: String
}

private struct UpdateAlbumParams: Encodable {
    let albumIdentifier: String

    enum CodingKeys: String, CodingKey {
        case albumIdentifier = "album_identifier"
    }
}
