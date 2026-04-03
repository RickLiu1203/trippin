//
//  TripDetailTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

@MainActor
final class MockTripMemberService: TripMemberService {
    var membersByTrip: [UUID: [TripMember]] = [:]
    var shouldFail = false
    var addCallCount = 0
    var removeCallCount = 0

    func fetchMembers(tripId: UUID) async throws -> [TripMember] {
        if shouldFail { throw TripServiceError.notAuthenticated }
        return membersByTrip[tripId] ?? []
    }

    func addMember(tripId: UUID, userId: UUID, displayName: String, emoji: String, color: String, role: MemberRole) async throws -> TripMember {
        if shouldFail { throw TripServiceError.notAuthenticated }

        if let existing = membersByTrip[tripId] {
            if existing.contains(where: { $0.emoji == emoji }) {
                throw TripServiceError.notAuthenticated
            }
            if existing.contains(where: { $0.color == color }) {
                throw TripServiceError.notAuthenticated
            }
        }

        addCallCount += 1
        let member = TripMember(
            id: UUID(),
            tripId: tripId,
            userId: userId,
            displayName: displayName,
            emoji: emoji,
            color: color,
            role: role,
            cameraIdentifier: nil,
            createdAt: Date()
        )
        membersByTrip[tripId, default: []].append(member)
        return member
    }

    func removeMember(id: UUID) async throws {
        if shouldFail { throw TripServiceError.notAuthenticated }
        removeCallCount += 1
        for tripId in membersByTrip.keys {
            membersByTrip[tripId]?.removeAll { $0.id == id }
        }
    }
}

@MainActor
final class MockSharedAlbumService: SharedAlbumService {
    var albums: [SharedAlbum] = []

    func fetchSharedAlbums() async -> [SharedAlbum] {
        albums
    }

    func fetchAlbum(id: String) async -> SharedAlbum? {
        albums.first { $0.id == id }
    }
}

private let testOwnerId = UUID()

private func makeTrip(name: String = "Test Trip", albumIdentifier: String? = nil) -> Trip {
    Trip(
        id: UUID(),
        ownerId: testOwnerId,
        name: name,
        shareCode: "abc123def456",
        albumIdentifier: albumIdentifier,
        createdAt: Date(),
        updatedAt: Date()
    )
}

private func makeMember(tripId: UUID, role: MemberRole = .member, emoji: String = "\u{1F525}", color: String = "#4ECDC4") -> TripMember {
    TripMember(
        id: UUID(),
        tripId: tripId,
        userId: UUID(),
        displayName: "Test User",
        emoji: emoji,
        color: color,
        role: role,
        cameraIdentifier: nil,
        createdAt: Date()
    )
}

@Suite("TripMemberService Mock Tests")
struct TripMemberServiceMockTests {
    @Test("fetchMembers returns members for trip")
    @MainActor
    func fetchMembers() async throws {
        let service = MockTripMemberService()
        let tripId = UUID()
        let member = makeMember(tripId: tripId)
        service.membersByTrip[tripId] = [member]

        let result = try await service.fetchMembers(tripId: tripId)
        #expect(result.count == 1)
        #expect(result[0].id == member.id)
    }

    @Test("addMember creates member")
    @MainActor
    func addMember() async throws {
        let service = MockTripMemberService()
        let tripId = UUID()

        let member = try await service.addMember(
            tripId: tripId,
            userId: UUID(),
            displayName: "Alice",
            emoji: "\u{1F338}",
            color: "#FF6B6B",
            role: .member
        )

        #expect(member.displayName == "Alice")
        #expect(service.addCallCount == 1)
        #expect(service.membersByTrip[tripId]?.count == 1)
    }

    @Test("removeMember removes member")
    @MainActor
    func removeMember() async throws {
        let service = MockTripMemberService()
        let tripId = UUID()
        let member = makeMember(tripId: tripId)
        service.membersByTrip[tripId] = [member]

        try await service.removeMember(id: member.id)

        #expect(service.membersByTrip[tripId]?.isEmpty == true)
        #expect(service.removeCallCount == 1)
    }

    @Test("addMember with taken emoji fails")
    @MainActor
    func emojiUniqueness() async throws {
        let service = MockTripMemberService()
        let tripId = UUID()
        service.membersByTrip[tripId] = [makeMember(tripId: tripId, emoji: "\u{1F338}")]

        await #expect(throws: (any Error).self) {
            _ = try await service.addMember(
                tripId: tripId,
                userId: UUID(),
                displayName: "Bob",
                emoji: "\u{1F338}",
                color: "#45B7D1",
                role: .guest
            )
        }
    }

    @Test("addMember with taken color fails")
    @MainActor
    func colorUniqueness() async throws {
        let service = MockTripMemberService()
        let tripId = UUID()
        service.membersByTrip[tripId] = [makeMember(tripId: tripId, color: "#FF6B6B")]

        await #expect(throws: (any Error).self) {
            _ = try await service.addMember(
                tripId: tripId,
                userId: UUID(),
                displayName: "Carol",
                emoji: "\u{2B50}",
                color: "#FF6B6B",
                role: .guest
            )
        }
    }
}

@Suite("TripDetailViewModel Tests")
struct TripDetailViewModelTests {
    @Test("loadTrip populates trip and members")
    @MainActor
    func loadTripPopulates() async {
        let tripService = MockTripService()
        let memberService = MockTripMemberService()
        let albumService = MockSharedAlbumService()

        let trip = makeTrip(name: "Tokyo Trip")
        tripService.trips = [trip]
        let owner = makeMember(tripId: trip.id, role: .owner)
        memberService.membersByTrip[trip.id] = [owner]

        let viewModel = TripDetailViewModel(
            tripId: trip.id,
            tripService: tripService,
            memberService: memberService,
            albumService: albumService
        )
        await viewModel.loadTrip()

        #expect(viewModel.trip?.name == "Tokyo Trip")
        #expect(viewModel.members.count == 1)
        #expect(!viewModel.isLoading)
    }

    @Test("loadTrip error sets error")
    @MainActor
    func loadTripError() async {
        let tripService = MockTripService()
        tripService.shouldFail = true

        let viewModel = TripDetailViewModel(
            tripId: UUID(),
            tripService: tripService,
            memberService: MockTripMemberService(),
            albumService: MockSharedAlbumService()
        )
        await viewModel.loadTrip()

        #expect(viewModel.error != nil)
        #expect(!viewModel.isLoading)
    }

    @Test("linkAlbum updates trip album identifier")
    @MainActor
    func linkAlbumUpdates() async {
        let tripService = MockTripService()
        let albumService = MockSharedAlbumService()
        albumService.albums = [SharedAlbum(id: "album-123", title: "Vacation", assetCount: 50)]

        let trip = makeTrip()
        tripService.trips = [trip]

        let viewModel = TripDetailViewModel(
            tripId: trip.id,
            tripService: tripService,
            memberService: MockTripMemberService(),
            albumService: albumService
        )
        await viewModel.loadTrip()
        await viewModel.linkAlbum("album-123")

        #expect(viewModel.trip?.albumIdentifier == "album-123")
        #expect(viewModel.linkedAlbum?.title == "Vacation")
    }

    @Test("removeMember removes from list")
    @MainActor
    func removeMemberRemoves() async {
        let tripService = MockTripService()
        let memberService = MockTripMemberService()

        let trip = makeTrip()
        tripService.trips = [trip]
        let owner = makeMember(tripId: trip.id, role: .owner)
        let guest = makeMember(tripId: trip.id, role: .guest, emoji: "\u{1F30A}", color: "#96CEB4")
        memberService.membersByTrip[trip.id] = [owner, guest]

        let viewModel = TripDetailViewModel(
            tripId: trip.id,
            tripService: tripService,
            memberService: memberService,
            albumService: MockSharedAlbumService()
        )
        await viewModel.loadTrip()
        #expect(viewModel.members.count == 2)

        await viewModel.removeMember(guest)

        #expect(viewModel.members.count == 1)
        #expect(viewModel.members[0].role == .owner)
    }

    @Test("isOwner returns true when userId matches trip owner")
    @MainActor
    func isOwnerCheck() async {
        let tripService = MockTripService()
        let trip = makeTrip()
        tripService.trips = [trip]

        let viewModel = TripDetailViewModel(
            tripId: trip.id,
            tripService: tripService,
            memberService: MockTripMemberService(),
            albumService: MockSharedAlbumService()
        )
        viewModel.userId = testOwnerId
        await viewModel.loadTrip()

        #expect(viewModel.isOwner)
    }

    @Test("isOwner returns false for non-owner")
    @MainActor
    func isNotOwner() async {
        let tripService = MockTripService()
        let trip = makeTrip()
        tripService.trips = [trip]

        let viewModel = TripDetailViewModel(
            tripId: trip.id,
            tripService: tripService,
            memberService: MockTripMemberService(),
            albumService: MockSharedAlbumService()
        )
        viewModel.userId = UUID()
        await viewModel.loadTrip()

        #expect(!viewModel.isOwner)
    }

    @Test("loadTrip fetches linked album info")
    @MainActor
    func loadTripWithAlbum() async {
        let tripService = MockTripService()
        let albumService = MockSharedAlbumService()
        albumService.albums = [SharedAlbum(id: "album-xyz", title: "Summer 2024", assetCount: 120)]

        let trip = makeTrip(albumIdentifier: "album-xyz")
        tripService.trips = [trip]

        let viewModel = TripDetailViewModel(
            tripId: trip.id,
            tripService: tripService,
            memberService: MockTripMemberService(),
            albumService: albumService
        )
        await viewModel.loadTrip()

        #expect(viewModel.linkedAlbum?.title == "Summer 2024")
        #expect(viewModel.linkedAlbum?.assetCount == 120)
    }
}

@Suite("EditTripViewModel Tests")
struct EditTripViewModelTests {
    @Test("initial name is populated")
    @MainActor
    func initialName() {
        let viewModel = EditTripViewModel(
            tripId: UUID(),
            currentName: "Paris Trip",
            albumIdentifier: nil,
            tripService: MockTripService()
        )
        #expect(viewModel.name == "Paris Trip")
        #expect(viewModel.isValid)
    }

    @Test("save with valid name succeeds")
    @MainActor
    func saveValid() async {
        let service = MockTripService()
        let trip = makeTrip(name: "Old Name")
        service.trips = [trip]

        let viewModel = EditTripViewModel(
            tripId: trip.id,
            currentName: "Old Name",
            albumIdentifier: nil,
            tripService: service
        )
        viewModel.name = "New Name"
        let result = await viewModel.save()

        #expect(result)
        #expect(!viewModel.isSaving)
    }

    @Test("save with empty name returns false")
    @MainActor
    func saveEmpty() async {
        let viewModel = EditTripViewModel(
            tripId: UUID(),
            currentName: "",
            albumIdentifier: nil,
            tripService: MockTripService()
        )
        viewModel.name = "   "
        let result = await viewModel.save()

        #expect(!result)
        #expect(!viewModel.isValid)
    }

    @Test("linkAlbum updates albumIdentifier")
    @MainActor
    func linkAlbumUpdatesIdentifier() async {
        let service = MockTripService()
        let trip = makeTrip()
        service.trips = [trip]

        let viewModel = EditTripViewModel(
            tripId: trip.id,
            currentName: trip.name,
            albumIdentifier: nil,
            tripService: service
        )

        await viewModel.linkAlbum("album-456")

        #expect(viewModel.albumIdentifier == "album-456")
    }
}

@Suite("SharedAlbumService Mock Tests")
struct SharedAlbumServiceMockTests {
    @Test("fetchSharedAlbums returns albums")
    @MainActor
    func fetchAlbums() async {
        let service = MockSharedAlbumService()
        service.albums = [
            SharedAlbum(id: "1", title: "Trip A", assetCount: 10),
            SharedAlbum(id: "2", title: "Trip B", assetCount: 20),
        ]

        let result = await service.fetchSharedAlbums()
        #expect(result.count == 2)
    }

    @Test("fetchAlbum returns matching album")
    @MainActor
    func fetchSingleAlbum() async {
        let service = MockSharedAlbumService()
        service.albums = [SharedAlbum(id: "abc", title: "My Album", assetCount: 42)]

        let album = await service.fetchAlbum(id: "abc")
        #expect(album?.title == "My Album")
        #expect(album?.assetCount == 42)
    }

    @Test("fetchAlbum returns nil for missing album")
    @MainActor
    func fetchMissingAlbum() async {
        let service = MockSharedAlbumService()
        let album = await service.fetchAlbum(id: "nonexistent")
        #expect(album == nil)
    }
}
