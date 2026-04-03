//
//  ProfilePlaceholderScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct ProfilePlaceholderScreen: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.paperTextSecondary)
            Text("Profile")
                .font(.paperDisplay(24, weight: .bold))
                .foregroundStyle(Color.paperText)
            Text("Your profile and settings")
                .font(.paperBody())
                .foregroundStyle(Color.paperTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .navigationTitle("Profile")
    }
}
