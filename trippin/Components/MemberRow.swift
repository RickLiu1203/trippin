//
//  MemberRow.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct MemberRow: View {
    let member: TripMember
    var showRemove: Bool = false
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color(hex: member.color))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.emoji)
                        .font(.system(size: 20))
                )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(member.displayName.isEmpty ? "Anonymous" : member.displayName)
                    .font(.paperBody(16, weight: .regular))
                    .foregroundStyle(Color.paperText)

                if member.role == .owner {
                    Text("Owner")
                        .paperChip(
                            foreground: .paperSecondary,
                            background: Color.paperSecondary.opacity(0.1),
                            bordered: false
                        )
                }
            }

            Spacer()

            if showRemove {
                Button(role: .destructive) {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.paperDanger.opacity(0.6))
                        .font(.system(size: 20))
                }
                .accessibilityLabel("Remove \(member.displayName)")
                .accessibilityHint("Double tap to remove this member from the trip")
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
