//
//  TimelineUITests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

private let baseDate = Date(timeIntervalSince1970: 1_700_035_200)

private func makePhotoCluster(
    tripId: UUID,
    dayIndex: Int,
    clusterOrder: Int,
    startOffset: TimeInterval = 0,
    photoCount: Int = 3
) -> PhotoCluster {
    PhotoCluster(
        id: UUID(),
        tripId: tripId,
        centroidLat: 35.68,
        centroidLon: 139.77,
        startTime: baseDate.addingTimeInterval(Double(dayIndex) * 86400 + startOffset),
        endTime: baseDate.addingTimeInterval(Double(dayIndex) * 86400 + startOffset + 1800),
        dayIndex: dayIndex,
        clusterOrder: clusterOrder,
        placeId: nil,
        photoCount: photoCount
    )
}

@Suite("Timeline GenerateFromDB Tests")
struct TimelineGenerateFromDBTests {
    @Test("generates days from stored clusters")
    func generatesFromDB() {
        let tripId = UUID()
        let cluster1 = makePhotoCluster(tripId: tripId, dayIndex: 0, clusterOrder: 0)
        let cluster2 = makePhotoCluster(tripId: tripId, dayIndex: 1, clusterOrder: 0, startOffset: 0)

        let photoId1 = UUID(), photoId2 = UUID()
        let clusterPhotos = [
            ClusterPhoto(id: UUID(), clusterId: cluster1.id, photoMetadataId: photoId1),
            ClusterPhoto(id: UUID(), clusterId: cluster2.id, photoMetadataId: photoId2),
        ]

        let metadata = [
            PhotoMetadata(id: photoId1, tripId: tripId, memberId: nil, localAssetId: "a1",
                          latitude: 35.68, longitude: 139.77, takenAt: baseDate,
                          cameraMake: nil, cameraModel: nil, cameraSerial: nil,
                          category: .food, confidence: 0.9, dayIndex: 0),
            PhotoMetadata(id: photoId2, tripId: tripId, memberId: nil, localAssetId: "a2",
                          latitude: 35.68, longitude: 139.77, takenAt: baseDate.addingTimeInterval(86400),
                          cameraMake: nil, cameraModel: nil, cameraSerial: nil,
                          category: .scenery, confidence: 0.8, dayIndex: 1),
        ]

        let days = TimelineGenerator.generateFromDB(
            clusters: [cluster1, cluster2],
            clusterPhotos: clusterPhotos,
            metadata: metadata
        )

        #expect(days.count == 2)
        #expect(days[0].dayIndex == 0)
        #expect(days[1].dayIndex == 1)
    }

    @Test("event has correct dominant category from DB data")
    func dominantCategoryFromDB() {
        let tripId = UUID()
        let cluster = makePhotoCluster(tripId: tripId, dayIndex: 0, clusterOrder: 0, photoCount: 3)

        let id1 = UUID(), id2 = UUID(), id3 = UUID()
        let clusterPhotos = [
            ClusterPhoto(id: UUID(), clusterId: cluster.id, photoMetadataId: id1),
            ClusterPhoto(id: UUID(), clusterId: cluster.id, photoMetadataId: id2),
            ClusterPhoto(id: UUID(), clusterId: cluster.id, photoMetadataId: id3),
        ]

        let metadata = [
            PhotoMetadata(id: id1, tripId: tripId, memberId: nil, localAssetId: "a1",
                          latitude: 35.68, longitude: 139.77, takenAt: baseDate,
                          cameraMake: nil, cameraModel: nil, cameraSerial: nil,
                          category: .food, confidence: 0.9, dayIndex: 0),
            PhotoMetadata(id: id2, tripId: tripId, memberId: nil, localAssetId: "a2",
                          latitude: 35.68, longitude: 139.77, takenAt: baseDate,
                          cameraMake: nil, cameraModel: nil, cameraSerial: nil,
                          category: .food, confidence: 0.8, dayIndex: 0),
            PhotoMetadata(id: id3, tripId: tripId, memberId: nil, localAssetId: "a3",
                          latitude: 35.68, longitude: 139.77, takenAt: baseDate,
                          cameraMake: nil, cameraModel: nil, cameraSerial: nil,
                          category: .scenery, confidence: 0.7, dayIndex: 0),
        ]

        let days = TimelineGenerator.generateFromDB(
            clusters: [cluster],
            clusterPhotos: clusterPhotos,
            metadata: metadata
        )

        let event = days[0].events.first { !$0.isTravelGap }!
        #expect(event.dominantCategory == .food)
    }

    @Test("empty clusters produce empty days")
    func emptyDB() {
        let days = TimelineGenerator.generateFromDB(clusters: [], clusterPhotos: [], metadata: [])
        #expect(days.isEmpty)
    }

    @Test("travel gap inserted between distant clusters on same day")
    func travelGapFromDB() {
        let tripId = UUID()
        let morning = makePhotoCluster(tripId: tripId, dayIndex: 0, clusterOrder: 0, startOffset: 0)
        let evening = makePhotoCluster(tripId: tripId, dayIndex: 0, clusterOrder: 1, startOffset: 10 * 3600)

        let days = TimelineGenerator.generateFromDB(
            clusters: [morning, evening],
            clusterPhotos: [],
            metadata: []
        )

        #expect(days.count == 1)
        let gaps = days[0].events.filter { $0.isTravelGap }
        #expect(gaps.count == 1)
    }
}
