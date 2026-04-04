//
//  ClusterService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Supabase

@MainActor
protocol ClusterService: Sendable {
    func replaceClusters(tripId: UUID, days: [TimelineDay]) async throws
    func fetchClusters(tripId: UUID) async throws -> [PhotoCluster]
    func fetchClusterPhotos(tripId: UUID) async throws -> [ClusterPhoto]
}

final class SupabaseClusterService: ClusterService {
    func replaceClusters(tripId: UUID, days: [TimelineDay]) async throws {
        try await supabase
            .from("photo_clusters")
            .delete()
            .eq("trip_id", value: tripId.uuidString)
            .execute()

        for day in days {
            var clusterOrder = 0
            for event in day.events where !event.isTravelGap {
                let insertParams = InsertClusterParams(
                    tripId: tripId,
                    centroidLat: event.centroidLat ?? 0,
                    centroidLon: event.centroidLon ?? 0,
                    startTime: event.startTime,
                    endTime: event.endTime,
                    dayIndex: day.dayIndex,
                    clusterOrder: clusterOrder,
                    photoCount: event.photoCount
                )

                let inserted: [PhotoCluster] = try await supabase
                    .from("photo_clusters")
                    .insert(insertParams)
                    .select()
                    .execute()
                    .value

                if let cluster = inserted.first, !event.photoMetadataIds.isEmpty {
                    let photos = event.photoMetadataIds.map {
                        InsertClusterPhotoParams(clusterId: cluster.id, photoMetadataId: $0)
                    }
                    try await supabase
                        .from("cluster_photos")
                        .insert(photos)
                        .execute()
                }

                clusterOrder += 1
            }
        }
    }

    func fetchClusters(tripId: UUID) async throws -> [PhotoCluster] {
        try await supabase
            .from("photo_clusters")
            .select()
            .eq("trip_id", value: tripId.uuidString)
            .order("day_index")
            .order("cluster_order")
            .execute()
            .value
    }

    func fetchClusterPhotos(tripId: UUID) async throws -> [ClusterPhoto] {
        let clusters = try await fetchClusters(tripId: tripId)
        guard !clusters.isEmpty else { return [] }
        let clusterIds = clusters.map(\.id.uuidString)
        return try await supabase
            .from("cluster_photos")
            .select()
            .in("cluster_id", values: clusterIds)
            .execute()
            .value
    }
}

private struct InsertClusterParams: Encodable {
    let tripId: UUID
    let centroidLat: Double
    let centroidLon: Double
    let startTime: Date
    let endTime: Date
    let dayIndex: Int
    let clusterOrder: Int
    let photoCount: Int

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case centroidLat = "centroid_lat"
        case centroidLon = "centroid_lon"
        case startTime = "start_time"
        case endTime = "end_time"
        case dayIndex = "day_index"
        case clusterOrder = "cluster_order"
        case photoCount = "photo_count"
    }
}

private struct InsertClusterPhotoParams: Encodable {
    let clusterId: UUID
    let photoMetadataId: UUID

    enum CodingKeys: String, CodingKey {
        case clusterId = "cluster_id"
        case photoMetadataId = "photo_metadata_id"
    }
}
