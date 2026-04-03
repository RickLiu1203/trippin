//
//  AuthGate.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

enum AuthGateDestination: Equatable {
    case loading
    case welcome
    case photoPermission
    case main
}

struct AuthGate: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(PhotoPermissionService.self) private var permissionService

    var destination: AuthGateDestination {
        Self.resolveDestination(
            authState: authViewModel.state,
            photoPermission: permissionService.status
        )
    }

    var body: some View {
        Group {
            switch destination {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.paperSurface)

            case .welcome:
                WelcomeScreen()

            case .photoPermission:
                PhotoPermissionScreen()

            case .main:
                // Placeholder until Step 5 wires up MainTabView
                ContentView()
            }
        }
        .paperAnimation(value: destination)
    }

    static func resolveDestination(
        authState: AuthState,
        photoPermission: PhotoPermissionStatus
    ) -> AuthGateDestination {
        switch authState {
        case .unknown, .loading:
            return .loading
        case .signedOut, .error:
            return .welcome
        case .signedIn:
            if photoPermission == .authorized {
                return .main
            } else {
                return .photoPermission
            }
        }
    }
}
