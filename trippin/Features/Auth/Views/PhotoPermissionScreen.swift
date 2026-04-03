//
//  PhotoPermissionScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct PhotoPermissionScreen: View {
    @Environment(PhotoPermissionService.self) private var permissionService

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(Color.paperPrimary)

            VStack(spacing: Spacing.sm) {
                Text("Photo Access Required")
                    .font(.paperDisplay(24, weight: .bold))
                    .foregroundStyle(Color.paperText)

                Text("trippin needs full access to your photo library to read photos from shared albums and reconstruct your trips.")
                    .font(.paperBody())
                    .foregroundStyle(Color.paperTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if permissionService.status == .denied {
                VStack(spacing: Spacing.md) {
                    Text("Photo access was denied. Please enable it in Settings to continue.")
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperDanger)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.paperSecondary)
                }
            } else if permissionService.status == .limited {
                VStack(spacing: Spacing.md) {
                    Text("Limited access won't work — trippin needs full library access to read shared albums.")
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperWarning)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.paperSecondary)
                }
            } else {
                Button("Allow Photo Access") {
                    Task {
                        await permissionService.requestAccess()
                    }
                }
                .buttonStyle(.paperPrimary)
            }

            Spacer()
                .frame(height: Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
        .background(Color.paperSurface)
    }
}
