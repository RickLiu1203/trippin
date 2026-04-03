//
//  AuthViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Auth
import AuthenticationServices
import Foundation
import Observation

enum AuthState: Equatable {
    case unknown
    case signedOut
    case loading
    case signedIn(userId: UUID)
    case error(String)
}

@MainActor
@Observable
final class AuthViewModel {
    private(set) var state: AuthState = .unknown
    private(set) var isAnonymous: Bool = false

    let authService: AuthService
    private var observeTask: Task<Void, Never>?

    init(authService: AuthService? = nil) {
        self.authService = authService ?? SupabaseAuthService()
    }

    func startObservingAuthState() {
        observeTask?.cancel()
        observeTask = Task { [authService] in
            for await (event, session) in authService.authStateChanges {
                guard !Task.isCancelled else { return }
                switch event {
                case .initialSession, .signedIn:
                    if let session {
                        self.isAnonymous = session.user.isAnonymous
                        self.state = .signedIn(userId: session.user.id)
                    } else {
                        self.state = .signedOut
                    }
                case .signedOut:
                    self.isAnonymous = false
                    self.state = .signedOut
                default:
                    break
                }
            }
        }
    }

    func stopObservingAuthState() {
        observeTask?.cancel()
        observeTask = nil
    }

    // MARK: - Apple Sign In

    func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) async {
        guard case .success(let authorization) = result else {
            if case .failure(let error) = result {
                state = .error(error.localizedDescription)
            }
            return
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8)
        else {
            state = .error("Invalid Apple credentials")
            return
        }

        state = .loading
        do {
            let session = try await authService.signInWithAppleIdToken(idToken)

            if let fullName = credential.fullName?.formatted(), !fullName.isEmpty {
                _ = try? await authService.updateUser(
                    UserAttributes(data: ["full_name": .string(fullName)])
                )
            }

            isAnonymous = false
            state = .signedIn(userId: session.user.id)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Anonymous Sign In

    func signInAnonymously() async {
        state = .loading
        do {
            let session = try await authService.signInAnonymously()
            isAnonymous = true
            state = .signedIn(userId: session.user.id)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authService.signOut()
            isAnonymous = false
            state = .signedOut
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
