//
//  EmptyStateView.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.paperTextSecondary)

            Text(title)
                .font(.paperDisplay(24, weight: .bold))
                .foregroundStyle(Color.paperText)

            Text(message)
                .font(.paperBody())
                .foregroundStyle(Color.paperTextSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.paperPrimary)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .accessibilityElement(children: .combine)
    }
}
