//
//  DeviceMatcher.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

enum DeviceMatchResult: Sendable, Equatable {
    case matched(memberId: UUID)
    case needsClaim(cameraIdentifier: String, cameraModel: String?)
}

final class DeviceMatcher: Sendable {
    let mappingService: DeviceMappingService

    init(mappingService: DeviceMappingService) {
        self.mappingService = mappingService
    }

    func matchDevice(tripId: UUID, make: String?, model: String?, serial: String?) async throws -> DeviceMatchResult {
        let identifier = Self.generateIdentifier(make: make, model: model, serial: serial)

        if let mapping = try await mappingService.fetchMapping(tripId: tripId, cameraIdentifier: identifier) {
            return .matched(memberId: mapping.memberId)
        }

        return .needsClaim(cameraIdentifier: identifier, cameraModel: model)
    }

    func claimDevice(tripId: UUID, cameraIdentifier: String, memberId: UUID) async throws {
        _ = try await mappingService.createMapping(
            tripId: tripId,
            cameraIdentifier: cameraIdentifier,
            memberId: memberId
        )
    }

    static func generateIdentifier(make: String?, model: String?, serial: String?) -> String {
        [make ?? "", model ?? "", serial ?? ""].joined(separator: "|")
    }
}
