//
//  MapPlaceholderScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct MapPlaceholderScreen: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(Color.paperTextSecondary)
            Text("Map")
                .font(.paperDisplay(24, weight: .bold))
                .foregroundStyle(Color.paperText)
            Text("Your trip map will appear here")
                .font(.paperBody())
                .foregroundStyle(Color.paperTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .navigationTitle("Map")
    }
}
