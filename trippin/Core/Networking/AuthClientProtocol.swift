//
//  AuthClientProtocol.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Auth
import Foundation

/// Protocol abstracting auth operations for testability.
@MainActor
protocol AuthService: Sendable {
    var authStateChanges: AsyncStream<(AuthChangeEvent, Session?)> { get }
    func signInWithAppleIdToken(_ idToken: String) async throws -> Session
    func signInAnonymously() async throws -> Session
    func updateUser(_ attributes: UserAttributes) async throws -> User
    func signOut() async throws
}

/// Real implementation backed by Supabase AuthClient.
final class SupabaseAuthService: AuthService {
    nonisolated var authStateChanges: AsyncStream<(AuthChangeEvent, Session?)> {
        let source = supabase.auth.authStateChanges
        return AsyncStream { continuation in
            Task {
                for await (event, session) in source {
                    continuation.yield((event, session))
                }
                continuation.finish()
            }
        }
    }

    func signInWithAppleIdToken(_ idToken: String) async throws -> Session {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken)
        )
    }

    func signInAnonymously() async throws -> Session {
        try await supabase.auth.signInAnonymously()
    }

    func updateUser(_ attributes: UserAttributes) async throws -> User {
        try await supabase.auth.update(user: attributes)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }
}
