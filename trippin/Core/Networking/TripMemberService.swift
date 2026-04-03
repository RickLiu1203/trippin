//
//  TripMemberService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Supabase

@MainActor
protocol TripMemberService: Sendable {
    func fetchMembers(tripId: UUID) async throws -> [TripMember]
    func addMember(tripId: UUID, userId: UUID, displayName: String, emoji: String, color: String, role: MemberRole) async throws -> TripMember
    func removeMember(id: UUID) async throws
}

final class SupabaseTripMemberService: TripMemberService {
    func fetchMembers(tripId: UUID) async throws -> [TripMember] {
        try await supabase
            .from("trip_members")
            .select()
            .eq("trip_id", value: tripId.uuidString)
            .order("created_at")
            .execute()
            .value
    }

    func addMember(tripId: UUID, userId: UUID, displayName: String, emoji: String, color: String, role: MemberRole) async throws -> TripMember {
        try await supabase
            .from("trip_members")
            .insert(InsertMemberParams(
                tripId: tripId,
                userId: userId,
                displayName: displayName,
                emoji: emoji,
                color: color,
                role: role.rawValue
            ))
            .select()
            .single()
            .execute()
            .value
    }

    func removeMember(id: UUID) async throws {
        try await supabase
            .from("trip_members")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

private struct InsertMemberParams: Encodable {
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
