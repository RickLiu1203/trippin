//
//  DeviceClaimSheet.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct DeviceClaimSheet: View {
    @Environment(\.dismiss) private var dismiss
    let cameraModel: String?
    let members: [TripMember]
    let onClaim: (UUID) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "camera")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.paperSecondary)

                    Text("Who took these photos?")
                        .font(.paperDisplay(20, weight: .semibold))
                        .foregroundStyle(Color.paperText)

                    Text("We found photos from \(cameraModel ?? "an unknown device"). Select the member who owns this device.")
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.lg)

                VStack(spacing: 0) {
                    ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                        Button {
                            onClaim(member.id)
                            dismiss()
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Circle()
                                    .fill(Color(hex: member.color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(member.emoji)
                                            .font(.system(size: 20))
                                    )

                                Text(member.displayName.isEmpty ? "Anonymous" : member.displayName)
                                    .font(.paperBody(16, weight: .medium))
                                    .foregroundStyle(Color.paperText)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.paperBody(14))
                                    .foregroundStyle(Color.paperTextSecondary)
                            }
                            .padding(.vertical, Spacing.xs)
                            .padding(.horizontal, Spacing.md)
                            .frame(minHeight: 44)
                        }
                        .accessibilityLabel("Assign to \(member.displayName)")

                        if index < members.count - 1 {
                            Divider()
                                .padding(.leading, Spacing.md + 40 + Spacing.sm)
                        }
                    }
                }
                .paperCard(padding: 0)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .background(Color.paperSurface)
            .navigationTitle("Claim Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
            }
        }
    }
}
