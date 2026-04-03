//
//  EditTripViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class EditTripViewModel {
    var name: String
    private(set) var albumIdentifier: String?
    private(set) var isSaving = false
    var error: String?
    var showLinkAlbumSheet = false

    let tripId: UUID
    let tripService: TripService

    init(tripId: UUID, currentName: String, albumIdentifier: String?, tripService: TripService? = nil) {
        self.tripId = tripId
        self.name = currentName
        self.albumIdentifier = albumIdentifier
        self.tripService = tripService ?? SupabaseTripService()
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var isValid: Bool {
        !trimmedName.isEmpty
    }

    func save() async -> Bool {
        guard isValid else { return false }
        isSaving = true
        do {
            _ = try await tripService.updateTrip(id: tripId, name: trimmedName)
            isSaving = false
            return true
        } catch {
            self.error = error.localizedDescription
            isSaving = false
            return false
        }
    }

    func linkAlbum(_ identifier: String) async {
        do {
            _ = try await tripService.updateTripAlbum(id: tripId, albumIdentifier: identifier)
            albumIdentifier = identifier
        } catch {
            self.error = error.localizedDescription
        }
    }
}
