//
//  GuestJoinViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class GuestJoinViewModel {
    var displayName: String = ""
    var selectedEmoji: String = ""
    var selectedColor: String = ""

    let takenEmojis: Set<String>
    let takenColors: Set<String>

    init(takenEmojis: Set<String> = [], takenColors: Set<String> = []) {
        self.takenEmojis = takenEmojis
        self.takenColors = takenColors
    }

    var availableEmojis: [String] {
        GuestJoinViewModel.allEmojis.filter { !takenEmojis.contains($0) }
    }

    var availableColors: [String] {
        GuestJoinViewModel.allColors.filter { !takenColors.contains($0) }
    }

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && !selectedEmoji.isEmpty
            && !selectedColor.isEmpty
    }

    var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespaces)
    }

    func selectDefaults() {
        if selectedEmoji.isEmpty, let first = availableEmojis.first {
            selectedEmoji = first
        }
        if selectedColor.isEmpty, let first = availableColors.first {
            selectedColor = first
        }
    }

    static let allEmojis = [
        "🌸", "🔥", "⭐️", "🌊", "🍕", "🎸",
        "🦋", "🌴", "🍜", "🎯", "🚀", "🌈",
        "🐱", "🎵", "💎", "🌻", "🎪", "🦊",
    ]

    static let allColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
        "#BB8FCE", "#85C1E9", "#F0B27A", "#82E0AA",
    ]
}
