//
//  JoinTripViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class JoinTripViewModel {
    let shareCode: String
    private(set) var tripId: UUID?
    private(set) var takenEmojis: Set<String> = []
    private(set) var takenColors: Set<String> = []
    private(set) var guestJoinViewModel: GuestJoinViewModel?
    private(set) var isLoading = true
    private(set) var isJoining = false
    var error: String?

    let edgeFunctionService: EdgeFunctionService

    init(shareCode: String, edgeFunctionService: EdgeFunctionService? = nil) {
        self.shareCode = shareCode
        self.edgeFunctionService = edgeFunctionService ?? SupabaseEdgeFunctionService()
    }

    func loadTripInfo() async {
        isLoading = true
        error = nil
        do {
            let info = try await edgeFunctionService.fetchTakenIdentifiers(shareCode: shareCode)
            tripId = info.tripId
            takenEmojis = Set(info.emojis)
            takenColors = Set(info.colors)
            guestJoinViewModel = GuestJoinViewModel(
                takenEmojis: takenEmojis,
                takenColors: takenColors
            )
            guestJoinViewModel?.selectDefaults()
            isLoading = false
        } catch {
            self.error = String(describing: error)
            isLoading = false
        }
    }

    func joinTrip(displayName: String, emoji: String, color: String) async -> UUID? {
        isJoining = true
        error = nil
        do {
            let result = try await edgeFunctionService.joinTrip(
                shareCode: shareCode,
                displayName: displayName,
                emoji: emoji,
                color: color
            )
            isJoining = false
            return result.tripId
        } catch let joinError as JoinTripError {
            isJoining = false
            if case .alreadyMember(let existingTripId) = joinError {
                return existingTripId
            }
            self.error = joinError.localizedDescription
            return nil
        } catch {
            self.error = error.localizedDescription
            isJoining = false
            return nil
        }
    }
}
