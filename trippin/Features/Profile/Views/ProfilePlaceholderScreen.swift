//
//  ProfilePlaceholderScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct ProfilePlaceholderScreen: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "person.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.paperTextSecondary)
            Text("Profile")
                .font(.paperDisplay(24, weight: .bold))
                .foregroundStyle(Color.paperText)
            Text("Your profile and settings")
                .font(.paperBody())
                .foregroundStyle(Color.paperTextSecondary)

            Spacer()

            Button("Sign Out") {
                Task {
                    await authViewModel.signOut()
                }
            }
            .buttonStyle(.paperDanger)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .navigationTitle("Profile")
    }
}
