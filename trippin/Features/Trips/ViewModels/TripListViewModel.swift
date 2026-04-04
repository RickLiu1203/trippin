//
//  TripListViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class TripListViewModel {
    private(set) var trips: [Trip] = []
    private(set) var membersByTrip: [UUID: [TripMember]] = [:]
    private(set) var photoCountsByTrip: [UUID: Int] = [:]
    private(set) var isLoading = false
    var error: String?
    var showCreateSheet = false

    let tripService: TripService

    init(tripService: TripService? = nil) {
        self.tripService = tripService ?? SupabaseTripService()
    }

    var linkedAlbumIds: Set<String> {
        Set(trips.compactMap(\.albumIdentifier))
    }

    func loadTrips() async {
        isLoading = true
        error = nil
        do {
            trips = try await tripService.fetchTrips()
            await loadTripDetails()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func createTripFromAlbum(_ album: SharedAlbum) async -> UUID? {
        do {
            let trip = try await tripService.createTrip(name: album.title, albumIdentifier: album.id)
            trips.insert(trip, at: 0)
            let members = try? await tripService.fetchMembers(tripId: trip.id)
            membersByTrip[trip.id] = members ?? []
            photoCountsByTrip[trip.id] = 0
            return trip.id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func deleteTrip(_ trip: Trip) async {
        do {
            try await tripService.deleteTrip(id: trip.id)
            trips.removeAll { $0.id == trip.id }
            membersByTrip.removeValue(forKey: trip.id)
            photoCountsByTrip.removeValue(forKey: trip.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadTripDetails() async {
        let service = tripService
        await withTaskGroup(of: (UUID, [TripMember], Int).self) { group in
            for trip in trips {
                group.addTask {
                    let members = (try? await service.fetchMembers(tripId: trip.id)) ?? []
                    let count = (try? await service.fetchPhotoCount(tripId: trip.id)) ?? 0
                    return (trip.id, members, count)
                }
            }
            for await (tripId, members, count) in group {
                membersByTrip[tripId] = members
                photoCountsByTrip[tripId] = count
            }
        }
    }
}
