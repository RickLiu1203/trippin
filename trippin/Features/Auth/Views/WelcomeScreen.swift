//
//  WelcomeScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import AuthenticationServices
import SwiftUI

struct WelcomeScreen: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // App branding
            VStack(spacing: Spacing.sm) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.paperPrimary)

                Text("trippin")
                    .font(.paperDisplay(40, weight: .bold))
                    .foregroundStyle(Color.paperText)

                Text("Reconstruct your trips from photos")
                    .font(.paperBody(16))
                    .foregroundStyle(Color.paperTextSecondary)
            }

            Spacer()

            // Auth buttons
            VStack(spacing: Spacing.md) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    Task {
                        await authViewModel.handleAppleSignIn(result)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                if case .error(let message) = authViewModel.state {
                    Text(message)
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperDanger)
                        .multilineTextAlignment(.center)
                }

                if case .loading = authViewModel.state {
                    ProgressView()
                        .tint(Color.paperPrimary)
                }
            }

            Spacer()
                .frame(height: Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
        .background(Color.paperSurface)
    }
}
