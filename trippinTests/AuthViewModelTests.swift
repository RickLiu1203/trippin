//
//  AuthViewModelTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
import Auth
@testable import trippin

// MARK: - Mock Auth Service

@MainActor
final class MockAuthService: AuthService {
    var signInAnonymouslyResult: Result<Session, Error> = .success(MockAuthService.makeSession())
    var signInWithAppleResult: Result<Session, Error> = .success(MockAuthService.makeSession())
    var signOutResult: Result<Void, Error> = .success(())
    var updateUserResult: Result<User, Error> = .success(MockAuthService.makeUser())

    private let continuation: AsyncStream<(AuthChangeEvent, Session?)>.Continuation
    private let _authStateChanges: AsyncStream<(AuthChangeEvent, Session?)>

    nonisolated var authStateChanges: AsyncStream<(AuthChangeEvent, Session?)> {
        _authStateChanges
    }

    init() {
        let (stream, continuation) = AsyncStream<(AuthChangeEvent, Session?)>.makeStream()
        self._authStateChanges = stream
        self.continuation = continuation
    }

    func emitAuthEvent(_ event: AuthChangeEvent, session: Session?) {
        continuation.yield((event, session))
    }

    func finishStream() {
        continuation.finish()
    }

    func signInWithAppleIdToken(_ idToken: String) async throws -> Session {
        try signInWithAppleResult.get()
    }

    func signInAnonymously() async throws -> Session {
        try signInAnonymouslyResult.get()
    }

    func updateUser(_ attributes: UserAttributes) async throws -> User {
        try updateUserResult.get()
    }

    func signOut() async throws {
        try signOutResult.get()
    }

    // MARK: - Helpers

    static func makeUser(id: UUID = UUID(), isAnonymous: Bool = false) -> User {
        User(
            id: id,
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            createdAt: Date(),
            updatedAt: Date(),
            isAnonymous: isAnonymous
        )
    }

    static func makeSession(userId: UUID = UUID(), isAnonymous: Bool = false) -> Session {
        Session(
            accessToken: "mock-access-token",
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: Date().timeIntervalSince1970 + 3600,
            refreshToken: "mock-refresh-token",
            user: makeUser(id: userId, isAnonymous: isAnonymous)
        )
    }
}

// MARK: - Test Errors

enum MockError: Error, LocalizedError {
    case authFailed

    var errorDescription: String? { "Auth failed" }
}

// MARK: - Tests

@Suite("AuthViewModel Tests")
struct AuthViewModelTests {

    @MainActor
    @Test("initial state is unknown")
    func initialState() {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        #expect(vm.state == .unknown)
        #expect(vm.isAnonymous == false)
    }

    @MainActor
    @Test("anonymous sign in transitions to signedIn")
    func anonymousSignIn() async {
        let userId = UUID()
        let mock = MockAuthService()
        mock.signInAnonymouslyResult = .success(MockAuthService.makeSession(userId: userId, isAnonymous: true))

        let vm = AuthViewModel(authService: mock)
        await vm.signInAnonymously()

        #expect(vm.state == .signedIn(userId: userId))
        #expect(vm.isAnonymous == true)
    }

    @MainActor
    @Test("anonymous sign in transitions from unknown to signedIn")
    func anonymousSignInTransition() async {
        let userId = UUID()
        let mock = MockAuthService()
        mock.signInAnonymouslyResult = .success(MockAuthService.makeSession(userId: userId))
        let vm = AuthViewModel(authService: mock)

        #expect(vm.state == .unknown)
        await vm.signInAnonymously()
        #expect(vm.state == .signedIn(userId: userId))
    }

    @MainActor
    @Test("anonymous sign in failure shows error")
    func anonymousSignInError() async {
        let mock = MockAuthService()
        mock.signInAnonymouslyResult = .failure(MockError.authFailed)

        let vm = AuthViewModel(authService: mock)
        await vm.signInAnonymously()

        #expect(vm.state == .error("Auth failed"))
        #expect(vm.isAnonymous == false)
    }

    @MainActor
    @Test("sign out clears state")
    func signOut() async {
        let userId = UUID()
        let mock = MockAuthService()
        mock.signInAnonymouslyResult = .success(MockAuthService.makeSession(userId: userId, isAnonymous: true))

        let vm = AuthViewModel(authService: mock)
        await vm.signInAnonymously()
        #expect(vm.state == .signedIn(userId: userId))
        #expect(vm.isAnonymous == true)

        await vm.signOut()
        #expect(vm.state == .signedOut)
        #expect(vm.isAnonymous == false)
    }

    @MainActor
    @Test("sign out failure shows error")
    func signOutError() async {
        let mock = MockAuthService()
        mock.signOutResult = .failure(MockError.authFailed)

        let vm = AuthViewModel(authService: mock)
        await vm.signInAnonymously()

        await vm.signOut()
        #expect(vm.state == .error("Auth failed"))
    }

    @MainActor
    @Test("auth state observation updates state on signedIn event")
    func observeSignedIn() async {
        let userId = UUID()
        let session = MockAuthService.makeSession(userId: userId)
        let mock = MockAuthService()

        let vm = AuthViewModel(authService: mock)
        vm.startObservingAuthState()

        mock.emitAuthEvent(.signedIn, session: session)

        // Yield to let the async stream process
        await Task.yield()
        await Task.yield()

        #expect(vm.state == .signedIn(userId: userId))

        vm.stopObservingAuthState()
    }

    @MainActor
    @Test("auth state observation updates state on signedOut event")
    func observeSignedOut() async {
        let mock = MockAuthService()

        let vm = AuthViewModel(authService: mock)
        vm.startObservingAuthState()

        mock.emitAuthEvent(.signedOut, session: nil)

        await Task.yield()
        await Task.yield()

        #expect(vm.state == .signedOut)
        #expect(vm.isAnonymous == false)

        vm.stopObservingAuthState()
    }

    @MainActor
    @Test("initial session with nil sets signedOut")
    func initialSessionNil() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        vm.startObservingAuthState()

        mock.emitAuthEvent(.initialSession, session: nil)

        await Task.yield()
        await Task.yield()

        #expect(vm.state == .signedOut)

        vm.stopObservingAuthState()
    }

    @MainActor
    @Test("stopObserving cancels the observation task")
    func stopObserving() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)

        vm.startObservingAuthState()
        vm.stopObservingAuthState()

        // After stopping, events should not update state
        mock.emitAuthEvent(.signedIn, session: MockAuthService.makeSession())

        await Task.yield()
        await Task.yield()

        #expect(vm.state == .unknown)
    }
}
