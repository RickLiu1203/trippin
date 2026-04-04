//
//  TripListTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

@MainActor
final class MockTripService: TripService {
    var trips: [Trip] = []
    var membersByTrip: [UUID: [TripMember]] = [:]
    var photoCountsByTrip: [UUID: Int] = [:]
    var shouldFail = false
    var createCallCount = 0
    var deleteCallCount = 0

    func fetchTrip(id: UUID) async throws -> Trip {
        if shouldFail { throw TripServiceError.notAuthenticated }
        guard let trip = trips.first(where: { $0.id == id }) else {
            throw TripServiceError.notAuthenticated
        }
        return trip
    }

    func fetchTrips() async throws -> [Trip] {
        if shouldFail { throw TripServiceError.notAuthenticated }
        return trips
    }

    func createTrip(name: String, albumIdentifier: String) async throws -> Trip {
        if shouldFail { throw TripServiceError.notAuthenticated }
        createCallCount += 1
        let trip = Trip(
            id: UUID(),
            ownerId: UUID(),
            name: name,
            shareCode: "abc123def456",
            albumIdentifier: albumIdentifier,
            createdAt: Date(),
            updatedAt: Date()
        )
        trips.insert(trip, at: 0)
        membersByTrip[trip.id] = [
            TripMember(
                id: UUID(),
                tripId: trip.id,
                userId: UUID(),
                displayName: "Owner",
                emoji: "\u{1F338}",
                color: "#FF6B6B",
                role: .owner,
                cameraIdentifier: nil,
                createdAt: Date()
            )
        ]
        return trip
    }

    func updateTrip(id: UUID, name: String) async throws -> Trip {
        if shouldFail { throw TripServiceError.notAuthenticated }
        guard let index = trips.firstIndex(where: { $0.id == id }) else {
            throw TripServiceError.notAuthenticated
        }
        var trip = trips[index]
        trip.name = name
        trip.updatedAt = Date()
        trips[index] = trip
        return trip
    }

    func deleteTrip(id: UUID) async throws {
        if shouldFail { throw TripServiceError.notAuthenticated }
        deleteCallCount += 1
        trips.removeAll { $0.id == id }
        membersByTrip.removeValue(forKey: id)
        photoCountsByTrip.removeValue(forKey: id)
    }

    func fetchMembers(tripId: UUID) async throws -> [TripMember] {
        if shouldFail { throw TripServiceError.notAuthenticated }
        return membersByTrip[tripId] ?? []
    }

    func fetchPhotoCount(tripId: UUID) async throws -> Int {
        if shouldFail { throw TripServiceError.notAuthenticated }
        return photoCountsByTrip[tripId] ?? 0
    }
}

private func makeTrip(name: String = "Test Trip") -> Trip {
    Trip(
        id: UUID(),
        ownerId: UUID(),
        name: name,
        shareCode: "abc123def456",
        albumIdentifier: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}

private func makeMember(tripId: UUID, emoji: String = "\u{1F338}", color: String = "#FF6B6B") -> TripMember {
    TripMember(
        id: UUID(),
        tripId: tripId,
        userId: UUID(),
        displayName: "Test User",
        emoji: emoji,
        color: color,
        role: .member,
        cameraIdentifier: nil,
        createdAt: Date()
    )
}

@Suite("TripService Mock Tests")
struct TripServiceMockTests {
    @Test("create then fetch returns same trip")
    @MainActor
    func createFetchRoundTrip() async throws {
        let service = MockTripService()
        let created = try await service.createTrip(name: "Tokyo 2024", albumIdentifier: "album-1")
        let fetched = try await service.fetchTrips()

        #expect(fetched.count == 1)
        #expect(fetched[0].id == created.id)
        #expect(fetched[0].name == "Tokyo 2024")
    }

    @Test("create trip auto-creates owner member")
    @MainActor
    func createTripCreatesOwner() async throws {
        let service = MockTripService()
        let trip = try await service.createTrip(name: "Paris Trip", albumIdentifier: "album-2")
        let members = try await service.fetchMembers(tripId: trip.id)

        #expect(members.count == 1)
        #expect(members[0].role == .owner)
    }

    @Test("delete trip removes from fetch results")
    @MainActor
    func deleteTripRemoves() async throws {
        let service = MockTripService()
        let trip = try await service.createTrip(name: "To Delete", albumIdentifier: "album-3")
        try await service.deleteTrip(id: trip.id)
        let fetched = try await service.fetchTrips()

        #expect(fetched.isEmpty)
    }

    @Test("update trip changes name")
    @MainActor
    func updateTripName() async throws {
        let service = MockTripService()
        let trip = try await service.createTrip(name: "Old Name", albumIdentifier: "album-4")
        let updated = try await service.updateTrip(id: trip.id, name: "New Name")

        #expect(updated.name == "New Name")
        #expect(updated.id == trip.id)
    }
}

@Suite("TripListViewModel Tests")
struct TripListViewModelTests {
    @Test("initial state is empty and not loading")
    @MainActor
    func initialState() {
        let service = MockTripService()
        let viewModel = TripListViewModel(tripService: service)

        #expect(viewModel.trips.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
        #expect(!viewModel.showCreateSheet)
    }

    @Test("loadTrips populates trips with members and photo counts")
    @MainActor
    func loadTripsPopulated() async {
        let service = MockTripService()
        let trip = makeTrip(name: "Tokyo 2024")
        service.trips = [trip]
        service.membersByTrip[trip.id] = [makeMember(tripId: trip.id)]
        service.photoCountsByTrip[trip.id] = 42

        let viewModel = TripListViewModel(tripService: service)
        await viewModel.loadTrips()

        #expect(viewModel.trips.count == 1)
        #expect(viewModel.trips[0].name == "Tokyo 2024")
        #expect(viewModel.membersByTrip[trip.id]?.count == 1)
        #expect(viewModel.photoCountsByTrip[trip.id] == 42)
        #expect(!viewModel.isLoading)
    }

    @Test("loadTrips with empty result shows empty state")
    @MainActor
    func loadTripsEmpty() async {
        let service = MockTripService()
        let viewModel = TripListViewModel(tripService: service)
        await viewModel.loadTrips()

        #expect(viewModel.trips.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    @Test("loadTrips failure sets error")
    @MainActor
    func loadTripsError() async {
        let service = MockTripService()
        service.shouldFail = true
        let viewModel = TripListViewModel(tripService: service)
        await viewModel.loadTrips()

        #expect(viewModel.error != nil)
        #expect(!viewModel.isLoading)
    }

    @Test("createTrip with name only succeeds")
    @MainActor
    func createTripNameOnly() async {
        let service = MockTripService()
        let viewModel = TripListViewModel(tripService: service)

        _ = await viewModel.createTripFromAlbum(SharedAlbum(id: "album-wg", title: "Weekend Getaway", assetCount: 10, isShared: true))

        #expect(viewModel.trips.count == 1)
        #expect(viewModel.trips[0].name == "Weekend Getaway")
        #expect(viewModel.error == nil)
        #expect(service.createCallCount == 1)
    }

    @Test("createTrip inserts at beginning of list")
    @MainActor
    func createTripInsertsAtBeginning() async {
        let service = MockTripService()
        let existing = makeTrip(name: "Old Trip")
        service.trips = [existing]
        let viewModel = TripListViewModel(tripService: service)
        await viewModel.loadTrips()

        _ = await viewModel.createTripFromAlbum(SharedAlbum(id: "album-new", title: "New Trip", assetCount: 5, isShared: false))

        #expect(viewModel.trips.count == 2)
        #expect(viewModel.trips[0].name == "New Trip")
        #expect(viewModel.trips[1].name == "Old Trip")
    }

    @Test("createTrip failure sets error")
    @MainActor
    func createTripError() async {
        let service = MockTripService()
        service.shouldFail = true
        let viewModel = TripListViewModel(tripService: service)

        _ = await viewModel.createTripFromAlbum(SharedAlbum(id: "album-fail", title: "Fail Trip", assetCount: 3, isShared: true))

        #expect(viewModel.trips.isEmpty)
        #expect(viewModel.error != nil)
    }

    @Test("deleteTrip removes trip from list")
    @MainActor
    func deleteTripRemoves() async {
        let service = MockTripService()
        let trip = makeTrip(name: "To Delete")
        service.trips = [trip]
        service.membersByTrip[trip.id] = [makeMember(tripId: trip.id)]
        let viewModel = TripListViewModel(tripService: service)
        await viewModel.loadTrips()
        #expect(viewModel.trips.count == 1)

        await viewModel.deleteTrip(trip)

        #expect(viewModel.trips.isEmpty)
        #expect(viewModel.membersByTrip[trip.id] == nil)
        #expect(service.deleteCallCount == 1)
    }

    @Test("deleteTrip failure sets error and keeps trip")
    @MainActor
    func deleteTripError() async {
        let service = MockTripService()
        let trip = makeTrip(name: "Persistent")
        service.trips = [trip]
        let viewModel = TripListViewModel(tripService: service)
        await viewModel.loadTrips()
        service.shouldFail = true

        await viewModel.deleteTrip(trip)

        #expect(viewModel.trips.count == 1)
        #expect(viewModel.error != nil)
    }

    @Test("loadTrips with multiple trips preserves order")
    @MainActor
    func loadTripsOrder() async {
        let service = MockTripService()
        let trip1 = makeTrip(name: "First")
        let trip2 = makeTrip(name: "Second")
        let trip3 = makeTrip(name: "Third")
        service.trips = [trip1, trip2, trip3]

        let viewModel = TripListViewModel(tripService: service)
        await viewModel.loadTrips()

        #expect(viewModel.trips.count == 3)
        #expect(viewModel.trips[0].name == "First")
        #expect(viewModel.trips[1].name == "Second")
        #expect(viewModel.trips[2].name == "Third")
    }
}
