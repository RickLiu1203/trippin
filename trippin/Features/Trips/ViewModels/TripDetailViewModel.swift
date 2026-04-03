//
//  TripDetailViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class TripDetailViewModel {
    private(set) var trip: Trip?
    private(set) var members: [TripMember] = []
    private(set) var linkedAlbum: SharedAlbum?
    private(set) var isLoading = false
    var error: String?
    var showEditSheet = false
    var showLinkAlbumSheet = false
    var showShareSheet = false
    var userId: UUID?

    let tripId: UUID
    let tripService: TripService
    let memberService: TripMemberService
    let albumService: SharedAlbumService

    init(
        tripId: UUID,
        tripService: TripService? = nil,
        memberService: TripMemberService? = nil,
        albumService: SharedAlbumService? = nil
    ) {
        self.tripId = tripId
        self.tripService = tripService ?? SupabaseTripService()
        self.memberService = memberService ?? SupabaseTripMemberService()
        self.albumService = albumService ?? PhotoKitSharedAlbumService()
    }

    var isOwner: Bool {
        trip?.ownerId == userId
    }

    func loadTrip() async {
        isLoading = true
        error = nil
        do {
            trip = try await tripService.fetchTrip(id: tripId)
            members = try await memberService.fetchMembers(tripId: tripId)
            if let albumId = trip?.albumIdentifier {
                linkedAlbum = await albumService.fetchAlbum(id: albumId)
            }
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func linkAlbum(_ albumIdentifier: String) async {
        do {
            trip = try await tripService.updateTripAlbum(id: tripId, albumIdentifier: albumIdentifier)
            linkedAlbum = await albumService.fetchAlbum(id: albumIdentifier)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeMember(_ member: TripMember) async {
        do {
            try await memberService.removeMember(id: member.id)
            members.removeAll { $0.id == member.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
