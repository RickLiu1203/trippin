//
//  ProfilePlaceholderScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct ProfilePlaceholderScreen: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AppRouter.self) private var router

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

            VStack(spacing: Spacing.sm) {
                Button("QA: Join as Guest (8gzyfg43325e)") {
                    Task {
                        await authViewModel.signOut()
                        try? await Task.sleep(for: .milliseconds(500))
                        await authViewModel.signInAnonymously()
                        router.pendingShareCode = "8gzyfg43325e"
                        router.selectedTab = .trips
                    }
                }
                .buttonStyle(.paperSecondary)
                .padding(.horizontal, Spacing.lg)

                Button("QA: Join as Current User") {
                    router.navigate(to: .guestJoin(shareCode: "8gzyfg43325e"), tab: .trips)
                }
                .buttonStyle(.paperSecondary)
                .padding(.horizontal, Spacing.lg)

                Button("Sign Out") {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                .buttonStyle(.paperDanger)
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperSurface)
        .navigationTitle("Profile")
    }
}
