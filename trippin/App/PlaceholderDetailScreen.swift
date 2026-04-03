//
//  PlaceholderDetailScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct PlaceholderDetailScreen: View {
    let title: String
    var id: UUID? = nil

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(title)
                .font(.paperDisplay(24, weight: .bold))
                .foregroundStyle(Color.paperText)
            if let id {
                Text(id.uuidString)
                    .font(.paperMono(12))
                    .foregroundStyle(Color.paperTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .navigationTitle(title)
    }
}
