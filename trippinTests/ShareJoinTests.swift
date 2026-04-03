//
//  ShareJoinTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

@MainActor
final class MockEdgeFunctionService: EdgeFunctionService {
    var takenIdentifiers: TripTakenIdentifiers?
    var joinResult: JoinTripResult?
    var joinError: Error?
    var shouldFail = false
    var joinCallCount = 0

    func joinTrip(shareCode: String, displayName: String, emoji: String, color: String) async throws -> JoinTripResult {
        joinCallCount += 1
        if let error = joinError { throw error }
        if shouldFail { throw JoinTripError.serverError("Mock failure") }
        guard let result = joinResult else { throw JoinTripError.tripNotFound }
        return result
    }

    func fetchTakenIdentifiers(shareCode: String) async throws -> TripTakenIdentifiers {
        if shouldFail { throw JoinTripError.tripNotFound }
        guard let identifiers = takenIdentifiers else { throw JoinTripError.tripNotFound }
        return identifiers
    }
}

@Suite("ShareTripViewModel Tests")
struct ShareTripViewModelTests {
    @Test("share URL format is correct")
    @MainActor
    func shareURLFormat() {
        let viewModel = ShareTripViewModel(shareCode: "abc123def456")
        #expect(viewModel.shareURL.absoluteString == "https://travelapp.app/trip/abc123def456")
    }

    @Test("share URL contains share code")
    @MainActor
    func shareURLContainsCode() {
        let viewModel = ShareTripViewModel(shareCode: "xyz789")
        #expect(viewModel.shareURL.absoluteString.contains("xyz789"))
    }

    @Test("QR code generation succeeds")
    @MainActor
    func qrCodeGenerated() {
        let viewModel = ShareTripViewModel(shareCode: "testcode123")
        #expect(viewModel.qrImage != nil)
    }

    @Test("copy sets copied flag")
    @MainActor
    func copySetsCopiedFlag() {
        let viewModel = ShareTripViewModel(shareCode: "abc123")
        #expect(!viewModel.copied)
        viewModel.copyURL()
        #expect(viewModel.copied)
    }
}

@Suite("JoinTripViewModel Tests")
struct JoinTripViewModelTests {
    @Test("loadTripInfo populates taken identifiers")
    @MainActor
    func loadTripInfo() async {
        let service = MockEdgeFunctionService()
        let tripId = UUID()
        service.takenIdentifiers = TripTakenIdentifiers(
            tripId: tripId,
            emojis: ["\u{1F338}", "\u{1F525}"],
            colors: ["#FF6B6B", "#4ECDC4"]
        )

        let viewModel = JoinTripViewModel(shareCode: "abc123", edgeFunctionService: service)
        await viewModel.loadTripInfo()

        #expect(viewModel.tripId == tripId)
        #expect(viewModel.takenEmojis.count == 2)
        #expect(viewModel.takenColors.count == 2)
        #expect(viewModel.guestJoinViewModel != nil)
        #expect(!viewModel.isLoading)
    }

    @Test("loadTripInfo creates GuestJoinViewModel with taken values")
    @MainActor
    func loadCreatesGuestVM() async {
        let service = MockEdgeFunctionService()
        service.takenIdentifiers = TripTakenIdentifiers(
            tripId: UUID(),
            emojis: ["\u{1F338}"],
            colors: ["#FF6B6B"]
        )

        let viewModel = JoinTripViewModel(shareCode: "abc123", edgeFunctionService: service)
        await viewModel.loadTripInfo()

        let guestVM = viewModel.guestJoinViewModel
        #expect(guestVM != nil)
        #expect(!guestVM!.availableEmojis.contains("\u{1F338}"))
        #expect(!guestVM!.availableColors.contains("#FF6B6B"))
    }

    @Test("loadTripInfo error sets error")
    @MainActor
    func loadError() async {
        let service = MockEdgeFunctionService()
        service.shouldFail = true

        let viewModel = JoinTripViewModel(shareCode: "invalid", edgeFunctionService: service)
        await viewModel.loadTripInfo()

        #expect(viewModel.error != nil)
        #expect(!viewModel.isLoading)
    }

    @Test("joinTrip success returns trip ID")
    @MainActor
    func joinSuccess() async {
        let service = MockEdgeFunctionService()
        let tripId = UUID()
        service.takenIdentifiers = TripTakenIdentifiers(tripId: tripId, emojis: [], colors: [])
        service.joinResult = JoinTripResult(tripId: tripId)

        let viewModel = JoinTripViewModel(shareCode: "abc123", edgeFunctionService: service)
        await viewModel.loadTripInfo()

        let resultId = await viewModel.joinTrip(displayName: "Alice", emoji: "\u{1F338}", color: "#FF6B6B")

        #expect(resultId == tripId)
        #expect(service.joinCallCount == 1)
        #expect(!viewModel.isJoining)
    }

    @Test("joinTrip already member returns existing trip ID")
    @MainActor
    func joinAlreadyMember() async {
        let service = MockEdgeFunctionService()
        let existingTripId = UUID()
        service.takenIdentifiers = TripTakenIdentifiers(tripId: existingTripId, emojis: [], colors: [])
        service.joinError = JoinTripError.alreadyMember(tripId: existingTripId)

        let viewModel = JoinTripViewModel(shareCode: "abc123", edgeFunctionService: service)
        await viewModel.loadTripInfo()

        let resultId = await viewModel.joinTrip(displayName: "Bob", emoji: "\u{1F525}", color: "#4ECDC4")

        #expect(resultId == existingTripId)
        #expect(viewModel.error == nil)
    }

    @Test("joinTrip failure sets error")
    @MainActor
    func joinFailure() async {
        let service = MockEdgeFunctionService()
        service.takenIdentifiers = TripTakenIdentifiers(tripId: UUID(), emojis: [], colors: [])
        service.shouldFail = true

        let viewModel = JoinTripViewModel(shareCode: "abc123", edgeFunctionService: service)
        await viewModel.loadTripInfo()

        let resultId = await viewModel.joinTrip(displayName: "Carol", emoji: "\u{2B50}", color: "#45B7D1")

        #expect(resultId == nil)
        #expect(viewModel.error != nil)
    }
}

@Suite("Deep Link Routing Tests")
struct DeepLinkRoutingTests {
    @Test("deep link for authenticated user routes to guest join")
    @MainActor
    func deepLinkAuthenticatedRoute() {
        let router = AppRouter()
        let url = URL(string: "https://travelapp.app/trip/abc123def456")!
        router.handleDeepLink(url)

        #expect(router.pendingShareCode == "abc123def456")
        #expect(router.selectedTab == .trips)

        let code = router.consumePendingShareCode()
        #expect(code == "abc123def456")
        #expect(router.pendingShareCode == nil)
    }

    @Test("duplicate join handled gracefully via already-member error")
    @MainActor
    func duplicateJoinHandled() async {
        let service = MockEdgeFunctionService()
        let tripId = UUID()
        service.takenIdentifiers = TripTakenIdentifiers(tripId: tripId, emojis: [], colors: [])
        service.joinError = JoinTripError.alreadyMember(tripId: tripId)

        let viewModel = JoinTripViewModel(shareCode: "abc123", edgeFunctionService: service)
        await viewModel.loadTripInfo()
        let resultId = await viewModel.joinTrip(displayName: "Test", emoji: "\u{1F338}", color: "#FF6B6B")

        #expect(resultId == tripId)
        #expect(viewModel.error == nil)
    }
}
