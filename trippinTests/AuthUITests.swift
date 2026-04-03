//
//  AuthUITests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
import SwiftUI
@testable import trippin

// MARK: - GuestJoinViewModel Tests

@Suite("GuestJoinViewModel Tests")
struct GuestJoinViewModelTests {
    @MainActor
    @Test("available emojis filters out taken emojis")
    func emojiFiltering() {
        let vm = GuestJoinViewModel(takenEmojis: ["🌸", "🔥", "⭐️"])
        let available = vm.availableEmojis
        #expect(!available.contains("🌸"))
        #expect(!available.contains("🔥"))
        #expect(!available.contains("⭐️"))
        #expect(available.contains("🌊"))
        #expect(available.count == GuestJoinViewModel.allEmojis.count - 3)
    }

    @MainActor
    @Test("available colors filters out taken colors")
    func colorFiltering() {
        let vm = GuestJoinViewModel(takenColors: ["#FF6B6B", "#4ECDC4"])
        let available = vm.availableColors
        #expect(!available.contains("#FF6B6B"))
        #expect(!available.contains("#4ECDC4"))
        #expect(available.contains("#45B7D1"))
        #expect(available.count == GuestJoinViewModel.allColors.count - 2)
    }

    @MainActor
    @Test("all emojis available when none taken")
    func allEmojisAvailable() {
        let vm = GuestJoinViewModel()
        #expect(vm.availableEmojis.count == GuestJoinViewModel.allEmojis.count)
    }

    @MainActor
    @Test("all colors available when none taken")
    func allColorsAvailable() {
        let vm = GuestJoinViewModel()
        #expect(vm.availableColors.count == GuestJoinViewModel.allColors.count)
    }

    @MainActor
    @Test("isValid requires non-empty name")
    func nameRequired() {
        let vm = GuestJoinViewModel()
        vm.selectedEmoji = "🌸"
        vm.selectedColor = "#FF6B6B"

        vm.displayName = ""
        #expect(!vm.isValid)

        vm.displayName = "   "
        #expect(!vm.isValid)

        vm.displayName = "Alice"
        #expect(vm.isValid)
    }

    @MainActor
    @Test("isValid requires emoji selection")
    func emojiRequired() {
        let vm = GuestJoinViewModel()
        vm.displayName = "Alice"
        vm.selectedColor = "#FF6B6B"
        vm.selectedEmoji = ""
        #expect(!vm.isValid)

        vm.selectedEmoji = "🌸"
        #expect(vm.isValid)
    }

    @MainActor
    @Test("isValid requires color selection")
    func colorRequired() {
        let vm = GuestJoinViewModel()
        vm.displayName = "Alice"
        vm.selectedEmoji = "🌸"
        vm.selectedColor = ""
        #expect(!vm.isValid)

        vm.selectedColor = "#FF6B6B"
        #expect(vm.isValid)
    }

    @MainActor
    @Test("trimmedName strips whitespace")
    func trimmedName() {
        let vm = GuestJoinViewModel()
        vm.displayName = "  Alice  "
        #expect(vm.trimmedName == "Alice")
    }

    @MainActor
    @Test("selectDefaults picks first available emoji and color")
    func selectDefaults() {
        let vm = GuestJoinViewModel()
        #expect(vm.selectedEmoji.isEmpty)
        #expect(vm.selectedColor.isEmpty)

        vm.selectDefaults()
        #expect(vm.selectedEmoji == GuestJoinViewModel.allEmojis.first)
        #expect(vm.selectedColor == GuestJoinViewModel.allColors.first)
    }

    @MainActor
    @Test("selectDefaults skips if already selected")
    func selectDefaultsPreservesExisting() {
        let vm = GuestJoinViewModel()
        vm.selectedEmoji = "🎸"
        vm.selectedColor = "#4ECDC4"

        vm.selectDefaults()
        #expect(vm.selectedEmoji == "🎸")
        #expect(vm.selectedColor == "#4ECDC4")
    }

    @Test("emoji pool has at least 12 options")
    func emojiPoolSize() {
        #expect(GuestJoinViewModel.allEmojis.count >= 12)
    }

    @Test("color pool has at least 12 options")
    func colorPoolSize() {
        #expect(GuestJoinViewModel.allColors.count >= 12)
    }

    @Test("all emojis are unique")
    func uniqueEmojis() {
        let unique = Set(GuestJoinViewModel.allEmojis)
        #expect(unique.count == GuestJoinViewModel.allEmojis.count)
    }

    @Test("all colors are unique")
    func uniqueColors() {
        let unique = Set(GuestJoinViewModel.allColors)
        #expect(unique.count == GuestJoinViewModel.allColors.count)
    }
}

// MARK: - AuthGate Tests

@Suite("AuthGate Routing Tests")
struct AuthGateTests {
    @Test("unknown auth state shows loading")
    func unknownShowsLoading() {
        let dest = AuthGate.resolveDestination(
            authState: .unknown,
            photoPermission: .notDetermined
        )
        #expect(dest == .loading)
    }

    @Test("loading auth state shows loading")
    func loadingShowsLoading() {
        let dest = AuthGate.resolveDestination(
            authState: .loading,
            photoPermission: .notDetermined
        )
        #expect(dest == .loading)
    }

    @Test("signedOut shows welcome")
    func signedOutShowsWelcome() {
        let dest = AuthGate.resolveDestination(
            authState: .signedOut,
            photoPermission: .notDetermined
        )
        #expect(dest == .welcome)
    }

    @Test("error state shows welcome")
    func errorShowsWelcome() {
        let dest = AuthGate.resolveDestination(
            authState: .error("Something went wrong"),
            photoPermission: .notDetermined
        )
        #expect(dest == .welcome)
    }

    @Test("signedIn without photo permission shows permission screen")
    func signedInNoPhotosShowsPermission() {
        let dest = AuthGate.resolveDestination(
            authState: .signedIn(userId: UUID()),
            photoPermission: .notDetermined
        )
        #expect(dest == .photoPermission)
    }

    @Test("signedIn with denied photos shows permission screen")
    func signedInDeniedPhotosShowsPermission() {
        let dest = AuthGate.resolveDestination(
            authState: .signedIn(userId: UUID()),
            photoPermission: .denied
        )
        #expect(dest == .photoPermission)
    }

    @Test("signedIn with limited photos shows permission screen")
    func signedInLimitedPhotosShowsPermission() {
        let dest = AuthGate.resolveDestination(
            authState: .signedIn(userId: UUID()),
            photoPermission: .limited
        )
        #expect(dest == .photoPermission)
    }

    @Test("signedIn with authorized photos shows main")
    func signedInAuthorizedShowsMain() {
        let dest = AuthGate.resolveDestination(
            authState: .signedIn(userId: UUID()),
            photoPermission: .authorized
        )
        #expect(dest == .main)
    }
}

// MARK: - Color Hex Init Tests

@Suite("Color Hex Init Tests")
struct ColorHexTests {
    @Test("parses hex with hash prefix")
    func withHash() {
        let _ = Color(hex: "#FF6B6B")
    }

    @Test("parses hex without hash prefix")
    func withoutHash() {
        let _ = Color(hex: "4ECDC4")
    }
}
