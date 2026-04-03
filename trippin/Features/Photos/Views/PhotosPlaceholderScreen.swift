//
//  PhotosPlaceholderScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct PhotosPlaceholderScreen: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(Color.paperTextSecondary)
            Text("Photos")
                .font(.paperDisplay(24, weight: .bold))
                .foregroundStyle(Color.paperText)
            Text("Your trip photos will appear here")
                .font(.paperBody())
                .foregroundStyle(Color.paperTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .navigationTitle("Photos")
    }
}
