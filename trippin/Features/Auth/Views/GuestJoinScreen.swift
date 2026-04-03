//
//  GuestJoinScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct GuestJoinScreen: View {
    @Bindable var viewModel: GuestJoinViewModel
    let onJoin: (String, String, String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Join Trip")
                    .font(.paperDisplay(32, weight: .bold))
                    .foregroundStyle(Color.paperText)

                // Name
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your name")
                        .font(.paperBody(14, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)

                    TextField("Enter your name", text: $viewModel.displayName)
                        .textFieldStyle(.paper)
                        .accessibilityLabel("Display name")
                        .accessibilityHint("Enter the name others will see")
                }

                // Emoji picker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Pick your emoji")
                        .font(.paperBody(14, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.xs) {
                        ForEach(viewModel.availableEmojis, id: \.self) { emoji in
                            Button {
                                viewModel.selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        viewModel.selectedEmoji == emoji
                                            ? Color.paperPrimary.opacity(0.1)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                                            .stroke(
                                                viewModel.selectedEmoji == emoji
                                                    ? Color.paperPrimary
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .accessibilityLabel(emoji)
                            .accessibilityAddTraits(viewModel.selectedEmoji == emoji ? .isSelected : [])
                        }
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Pick your color")
                        .font(.paperBody(14, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.xs) {
                        ForEach(viewModel.availableColors, id: \.self) { hex in
                            Button {
                                viewModel.selectedColor = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                viewModel.selectedColor == hex
                                                    ? Color.paperPrimary
                                                    : Color.paperBorder,
                                                lineWidth: viewModel.selectedColor == hex ? 3 : 1
                                            )
                                    )
                            }
                            .accessibilityLabel("Color \(hex)")
                            .accessibilityAddTraits(viewModel.selectedColor == hex ? .isSelected : [])
                        }
                    }
                }

                // Join button
                Button("Join Trip") {
                    onJoin(
                        viewModel.trimmedName,
                        viewModel.selectedEmoji,
                        viewModel.selectedColor
                    )
                }
                .buttonStyle(.paperPrimary)
                .disabled(!viewModel.isValid)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Join trip")
                .accessibilityHint(viewModel.isValid ? "Double tap to join" : "Enter your name, pick an emoji and color first")
            }
            .padding(Spacing.lg)
        }
        .background(Color.paperSurface)
        .onAppear {
            viewModel.selectDefaults()
        }
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
