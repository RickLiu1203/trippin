//
//  DeviceMatcherTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

@MainActor
final class MockDeviceMappingService: DeviceMappingService {
    var mappings: [String: DeviceMapping] = [:]
    var shouldFail = false

    private func key(tripId: UUID, cameraIdentifier: String) -> String {
        "\(tripId.uuidString)|\(cameraIdentifier)"
    }

    func fetchMapping(tripId: UUID, cameraIdentifier: String) async throws -> DeviceMapping? {
        if shouldFail { throw TripServiceError.notAuthenticated }
        return mappings[key(tripId: tripId, cameraIdentifier: cameraIdentifier)]
    }

    func createMapping(tripId: UUID, cameraIdentifier: String, memberId: UUID) async throws -> DeviceMapping {
        if shouldFail { throw TripServiceError.notAuthenticated }
        let mapping = DeviceMapping(
            id: UUID(),
            tripId: tripId,
            cameraIdentifier: cameraIdentifier,
            memberId: memberId
        )
        mappings[key(tripId: tripId, cameraIdentifier: cameraIdentifier)] = mapping
        return mapping
    }
}

@Suite("Device Identifier Generation Tests")
struct DeviceIdentifierTests {
    @Test("generates identifier with full data")
    func fullIdentifier() {
        let id = DeviceMatcher.generateIdentifier(make: "Apple", model: "iPhone 15 Pro", serial: "DNXXXXXX")
        #expect(id == "Apple|iPhone 15 Pro|DNXXXXXX")
    }

    @Test("generates identifier with nil serial")
    func nilSerial() {
        let id = DeviceMatcher.generateIdentifier(make: "Apple", model: "iPhone 15 Pro", serial: nil)
        #expect(id == "Apple|iPhone 15 Pro|")
    }

    @Test("generates identifier with all nil")
    func allNil() {
        let id = DeviceMatcher.generateIdentifier(make: nil, model: nil, serial: nil)
        #expect(id == "||")
    }

    @Test("same model different serial produces different identifiers")
    func differentSerials() {
        let id1 = DeviceMatcher.generateIdentifier(make: "Apple", model: "iPhone 15 Pro", serial: "AAA")
        let id2 = DeviceMatcher.generateIdentifier(make: "Apple", model: "iPhone 15 Pro", serial: "BBB")
        #expect(id1 != id2)
    }

    @Test("same model no serial produces same identifier")
    func sameModelNoSerial() {
        let id1 = DeviceMatcher.generateIdentifier(make: "Apple", model: "iPhone 15 Pro", serial: nil)
        let id2 = DeviceMatcher.generateIdentifier(make: "Apple", model: "iPhone 15 Pro", serial: nil)
        #expect(id1 == id2)
    }
}

@Suite("Device Matching Tests")
struct DeviceMatchingTests {
    @Test("returns matched when mapping exists")
    @MainActor
    func matchedExisting() async throws {
        let service = MockDeviceMappingService()
        let tripId = UUID()
        let memberId = UUID()
        let identifier = DeviceMatcher.generateIdentifier(make: "Apple", model: "iPhone 15 Pro", serial: "DN123")

        service.mappings["\(tripId.uuidString)|\(identifier)"] = DeviceMapping(
            id: UUID(),
            tripId: tripId,
            cameraIdentifier: identifier,
            memberId: memberId
        )

        let matcher = DeviceMatcher(mappingService: service)
        let result = try await matcher.matchDevice(tripId: tripId, make: "Apple", model: "iPhone 15 Pro", serial: "DN123")

        #expect(result == .matched(memberId: memberId))
    }

    @Test("returns needsClaim when no mapping exists")
    @MainActor
    func needsClaim() async throws {
        let service = MockDeviceMappingService()
        let matcher = DeviceMatcher(mappingService: service)
        let result = try await matcher.matchDevice(tripId: UUID(), make: "Apple", model: "iPhone 15 Pro", serial: nil)

        if case .needsClaim(let identifier, let model) = result {
            #expect(identifier == "Apple|iPhone 15 Pro|")
            #expect(model == "iPhone 15 Pro")
        } else {
            Issue.record("Expected needsClaim result")
        }
    }

    @Test("claim device creates mapping and subsequent match succeeds")
    @MainActor
    func claimThenMatch() async throws {
        let service = MockDeviceMappingService()
        let matcher = DeviceMatcher(mappingService: service)
        let tripId = UUID()
        let memberId = UUID()
        let identifier = DeviceMatcher.generateIdentifier(make: "Canon", model: "EOS R5", serial: "XYZ")

        let firstResult = try await matcher.matchDevice(tripId: tripId, make: "Canon", model: "EOS R5", serial: "XYZ")
        #expect(firstResult == .needsClaim(cameraIdentifier: identifier, cameraModel: "EOS R5"))

        try await matcher.claimDevice(tripId: tripId, cameraIdentifier: identifier, memberId: memberId)

        let secondResult = try await matcher.matchDevice(tripId: tripId, make: "Canon", model: "EOS R5", serial: "XYZ")
        #expect(secondResult == .matched(memberId: memberId))
    }

    @Test("same model no serial triggers claim for ambiguous devices")
    @MainActor
    func ambiguousDevices() async throws {
        let service = MockDeviceMappingService()
        let matcher = DeviceMatcher(mappingService: service)
        let tripId = UUID()

        let result1 = try await matcher.matchDevice(tripId: tripId, make: "Apple", model: "iPhone 15", serial: nil)
        let result2 = try await matcher.matchDevice(tripId: tripId, make: "Apple", model: "iPhone 15", serial: nil)

        if case .needsClaim(let id1, _) = result1,
           case .needsClaim(let id2, _) = result2 {
            #expect(id1 == id2)
        } else {
            Issue.record("Expected both to need claim")
        }
    }
}
