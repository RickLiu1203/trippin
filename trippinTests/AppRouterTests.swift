//
//  AppRouterTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

@Suite("AppRouter Tests")
struct AppRouterTests {

    @MainActor
    @Test("default tab is trips")
    func defaultTab() {
        let router = AppRouter()
        #expect(router.selectedTab == .trips)
    }

    @MainActor
    @Test("tab switching updates selectedTab")
    func tabSwitching() {
        let router = AppRouter()

        router.selectedTab = .map
        #expect(router.selectedTab == .map)

        router.selectedTab = .photos
        #expect(router.selectedTab == .photos)

        router.selectedTab = .profile
        #expect(router.selectedTab == .profile)

        router.selectedTab = .trips
        #expect(router.selectedTab == .trips)
    }

    @MainActor
    @Test("navigate appends to correct tab path")
    func navigate() {
        let router = AppRouter()

        router.selectedTab = .trips
        router.navigate(to: .tripDetail(tripId: UUID()))
        #expect(!router.tripsPath.isEmpty)
        #expect(router.mapPath.isEmpty)
    }

    @MainActor
    @Test("navigate with tab switches tab first")
    func navigateWithTab() {
        let router = AppRouter()

        router.navigate(to: .settings, tab: .profile)
        #expect(router.selectedTab == .profile)
        #expect(!router.profilePath.isEmpty)
    }

    @MainActor
    @Test("popToRoot clears the path")
    func popToRoot() {
        let router = AppRouter()

        router.selectedTab = .trips
        router.navigate(to: .tripDetail(tripId: UUID()))
        router.navigate(to: .editTrip(tripId: UUID()))
        #expect(!router.tripsPath.isEmpty)

        router.popToRoot()
        #expect(router.tripsPath.isEmpty)
    }

    @MainActor
    @Test("popToRoot for specific tab")
    func popToRootSpecificTab() {
        let router = AppRouter()

        router.navigate(to: .settings, tab: .profile)
        #expect(!router.profilePath.isEmpty)

        router.popToRoot(tab: .profile)
        #expect(router.profilePath.isEmpty)
    }
}

@Suite("Deep Link Parsing Tests")
struct DeepLinkTests {

    @Test("parses valid deep link URL")
    func validURL() {
        let url = URL(string: "https://travelapp.app/trip/abc123def456")!
        let code = AppRouter.parseShareCode(from: url)
        #expect(code == "abc123def456")
    }

    @Test("parses deep link with trailing slash")
    func trailingSlash() {
        let url = URL(string: "https://travelapp.app/trip/xyz789/")!
        let code = AppRouter.parseShareCode(from: url)
        #expect(code == "xyz789")
    }

    @Test("returns nil for missing share code")
    func missingCode() {
        let url = URL(string: "https://travelapp.app/trip/")!
        let code = AppRouter.parseShareCode(from: url)
        #expect(code == nil)
    }

    @Test("returns nil for wrong path")
    func wrongPath() {
        let url = URL(string: "https://travelapp.app/other/abc123")!
        let code = AppRouter.parseShareCode(from: url)
        #expect(code == nil)
    }

    @Test("returns nil for root URL")
    func rootURL() {
        let url = URL(string: "https://travelapp.app/")!
        let code = AppRouter.parseShareCode(from: url)
        #expect(code == nil)
    }

    @Test("returns nil for completely unrelated URL")
    func unrelatedURL() {
        let url = URL(string: "https://example.com")!
        let code = AppRouter.parseShareCode(from: url)
        #expect(code == nil)
    }

    @MainActor
    @Test("handleDeepLink sets pendingShareCode and switches to trips tab")
    func handleDeepLink() {
        let router = AppRouter()
        router.selectedTab = .profile

        let url = URL(string: "https://travelapp.app/trip/abc123")!
        router.handleDeepLink(url)

        #expect(router.pendingShareCode == "abc123")
        #expect(router.selectedTab == .trips)
    }

    @MainActor
    @Test("handleDeepLink ignores invalid URL")
    func handleInvalidDeepLink() {
        let router = AppRouter()
        let url = URL(string: "https://example.com/nope")!
        router.handleDeepLink(url)

        #expect(router.pendingShareCode == nil)
    }

    @MainActor
    @Test("consumePendingShareCode returns code and clears it")
    func consumeShareCode() {
        let router = AppRouter()
        router.pendingShareCode = "test123"

        let code = router.consumePendingShareCode()
        #expect(code == "test123")
        #expect(router.pendingShareCode == nil)
    }

    @MainActor
    @Test("consumePendingShareCode returns nil when empty")
    func consumeEmpty() {
        let router = AppRouter()
        let code = router.consumePendingShareCode()
        #expect(code == nil)
    }
}
