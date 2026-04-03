//
//  EdgeFunctionService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Functions
import Supabase

enum JoinTripError: Error, LocalizedError {
    case alreadyMember(tripId: UUID)
    case emojiTaken
    case colorTaken
    case tripNotFound
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .alreadyMember: "You're already a member of this trip"
        case .emojiTaken: "That emoji is already taken, pick another"
        case .colorTaken: "That color is already taken, pick another"
        case .tripNotFound: "Trip not found"
        case .serverError(let msg): msg
        }
    }
}

struct JoinTripResult: Sendable {
    let tripId: UUID
}

struct TripTakenIdentifiers: Decodable, Sendable {
    let tripId: UUID
    let emojis: [String]
    let colors: [String]

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case emojis
        case colors
    }
}

@MainActor
protocol EdgeFunctionService: Sendable {
    func joinTrip(shareCode: String, displayName: String, emoji: String, color: String) async throws -> JoinTripResult
    func fetchTakenIdentifiers(shareCode: String) async throws -> TripTakenIdentifiers
}

final class SupabaseEdgeFunctionService: EdgeFunctionService {
    func joinTrip(shareCode: String, displayName: String, emoji: String, color: String) async throws -> JoinTripResult {
        let request = JoinTripRequest(
            shareCode: shareCode,
            displayName: displayName,
            emoji: emoji,
            color: color
        )

        do {
            let decoder = JSONDecoder()
            let dto: JoinTripResponseDTO = try await supabase.functions.invoke(
                "join-trip",
                options: .init(body: request),
                decoder: decoder
            )
            return JoinTripResult(tripId: dto.tripId)
        } catch let FunctionsError.httpError(_, data) {
            throw parseErrorData(data)
        }
    }

    func fetchTakenIdentifiers(shareCode: String) async throws -> TripTakenIdentifiers {
        try await supabase
            .rpc("get_trip_taken_identifiers", params: ["p_share_code": shareCode])
            .execute()
            .value
    }

    private func parseErrorData(_ data: Data) -> Error {
        guard let dto = try? JSONDecoder().decode(JoinTripErrorDTO.self, from: data) else {
            return JoinTripError.serverError("Unknown error")
        }
        if let tripId = dto.tripId {
            return JoinTripError.alreadyMember(tripId: tripId)
        }
        if let msg = dto.error {
            if msg.contains("Emoji") { return JoinTripError.emojiTaken }
            if msg.contains("Color") { return JoinTripError.colorTaken }
            if msg.contains("not found") { return JoinTripError.tripNotFound }
            return JoinTripError.serverError(msg)
        }
        return JoinTripError.serverError("Unknown error")
    }
}

private struct JoinTripRequest: Encodable {
    let shareCode: String
    let displayName: String
    let emoji: String
    let color: String

    enum CodingKeys: String, CodingKey {
        case shareCode = "share_code"
        case displayName = "display_name"
        case emoji
        case color
    }
}

private struct JoinTripResponseDTO: Decodable {
    let tripId: UUID

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
    }
}

private struct JoinTripErrorDTO: Decodable {
    let error: String?
    let tripId: UUID?

    enum CodingKeys: String, CodingKey {
        case error
        case tripId = "trip_id"
    }
}
