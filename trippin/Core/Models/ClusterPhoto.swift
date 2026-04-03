//
//  ClusterPhoto.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct ClusterPhoto: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let clusterId: UUID
    let photoMetadataId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case clusterId = "cluster_id"
        case photoMetadataId = "photo_metadata_id"
    }
}
