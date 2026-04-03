//
//  TripsPlaceholderScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct TripsPlaceholderScreen: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "suitcase")
                .font(.system(size: 48))
                .foregroundStyle(Color.paperTextSecondary)
            Text("Trips")
                .font(.paperDisplay(24, weight: .bold))
                .foregroundStyle(Color.paperText)
            Text("Your trips will appear here")
                .font(.paperBody())
                .foregroundStyle(Color.paperTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .navigationTitle("Trips")
    }
}
