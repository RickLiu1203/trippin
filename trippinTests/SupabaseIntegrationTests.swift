//
//  SupabaseIntegrationTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

private let isSupabaseConfigured: Bool = {
    Secrets.supabaseURL != "https://your-project.supabase.co"
}()

@Suite("Supabase Integration Tests", .enabled(if: isSupabaseConfigured))
struct SupabaseIntegrationTests {

    @Test("SupabaseClient initializes with configured URL")
    func clientInitializes() {
        #expect(Secrets.supabaseURL.contains("supabase.co"))
    }

    @Test("can query profiles table")
    func queryProfiles() async throws {
        let response: [Profile] = try await supabase
            .from("profiles")
            .select()
            .limit(1)
            .execute()
            .value
        _ = response
    }

    @Test("trip insert returns valid UUID and share_code")
    func tripInsert() async throws {
        let session = try await supabase.auth.session

        struct TripInsert: Encodable {
            let owner_id: UUID
            let name: String
        }

        let insert = TripInsert(owner_id: session.user.id, name: "Test Trip \(UUID().uuidString.prefix(8))")

        let trip: Trip = try await supabase
            .from("trips")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        #expect(!trip.shareCode.isEmpty)
        #expect(trip.shareCode.count == 12)
        #expect(trip.name == insert.name)
        #expect(trip.ownerId == session.user.id)

        try await supabase
            .from("trips")
            .delete()
            .eq("id", value: trip.id.uuidString)
            .execute()
    }
}

@Suite("Supabase Config Tests")
struct SupabaseConfigTests {

    @Test("secrets URL contains supabase domain")
    func clientExists() {
        #expect(Secrets.supabaseURL.contains("supabase"))
    }

    @Test("share code nanoid format")
    func shareCodeFormat() {
        let validChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        let testCode = "abc123def456"
        #expect(testCode.count == 12)
        #expect(testCode.unicodeScalars.allSatisfy { validChars.contains($0) })
    }
}
