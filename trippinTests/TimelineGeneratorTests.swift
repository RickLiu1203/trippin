//
//  TimelineGeneratorTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

private let day1Morning = Date(timeIntervalSince1970: 1_700_035_200)
private let day1Afternoon = day1Morning.addingTimeInterval(6 * 3600)
private let day2Morning = day1Morning.addingTimeInterval(24 * 3600)
private let day2Afternoon = day2Morning.addingTimeInterval(6 * 3600)

private func makeCluster(
    ids: [UUID],
    lat: Double = 35.68,
    lon: Double = 139.77,
    startOffset: TimeInterval = 0,
    duration: TimeInterval = 1800
) -> ClusterResult {
    let points = ids.enumerated().map { i, id in
        PhotoPoint(
            id: id,
            latitude: lat,
            longitude: lon,
            takenAt: day1Morning.addingTimeInterval(startOffset + Double(i) * 300)
        )
    }
    return ClusterResult(
        points: points,
        centroidLat: lat,
        centroidLon: lon,
        startTime: day1Morning.addingTimeInterval(startOffset),
        endTime: day1Morning.addingTimeInterval(startOffset + duration)
    )
}

private func makeMetadata(id: UUID, category: PhotoCategory, memberId: UUID? = nil) -> PhotoMetadata {
    PhotoMetadata(
        id: id,
        tripId: UUID(),
        memberId: memberId,
        localAssetId: "asset-\(id.uuidString.prefix(8))",
        latitude: 35.68,
        longitude: 139.77,
        takenAt: Date(),
        cameraMake: nil,
        cameraModel: nil,
        cameraSerial: nil,
        category: category,
        confidence: 0.9,
        dayIndex: 0
    )
}

@Suite("Timeline Generation Tests")
struct TimelineGenerationTests {
    @Test("clusters across 2 days produce 2 TimelineDays")
    func twoDays() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID(), id4 = UUID()

        let cluster1 = ClusterResult(
            points: [
                PhotoPoint(id: id1, latitude: 35.68, longitude: 139.77, takenAt: day1Morning),
                PhotoPoint(id: id2, latitude: 35.68, longitude: 139.77, takenAt: day1Morning.addingTimeInterval(600)),
            ],
            centroidLat: 35.68, centroidLon: 139.77,
            startTime: day1Morning, endTime: day1Morning.addingTimeInterval(600)
        )

        let cluster2 = ClusterResult(
            points: [
                PhotoPoint(id: id3, latitude: 35.68, longitude: 139.77, takenAt: day2Morning),
                PhotoPoint(id: id4, latitude: 35.68, longitude: 139.77, takenAt: day2Morning.addingTimeInterval(600)),
            ],
            centroidLat: 35.68, centroidLon: 139.77,
            startTime: day2Morning, endTime: day2Morning.addingTimeInterval(600)
        )

        let metadata: [UUID: PhotoMetadata] = [
            id1: makeMetadata(id: id1, category: .food),
            id2: makeMetadata(id: id2, category: .food),
            id3: makeMetadata(id: id3, category: .scenery),
            id4: makeMetadata(id: id4, category: .scenery),
        ]

        let days = TimelineGenerator.generate(clusters: [cluster1, cluster2], metadata: metadata)
        #expect(days.count == 2)
        #expect(days[0].dayIndex == 0)
        #expect(days[1].dayIndex == 1)
    }

    @Test("events within day ordered chronologically")
    func chronologicalOrder() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID(), id4 = UUID()

        let laterCluster = makeCluster(ids: [id1, id2], startOffset: 7200, duration: 600)
        let earlierCluster = makeCluster(ids: [id3, id4], startOffset: 0, duration: 600)

        let metadata: [UUID: PhotoMetadata] = [
            id1: makeMetadata(id: id1, category: .food),
            id2: makeMetadata(id: id2, category: .food),
            id3: makeMetadata(id: id3, category: .scenery),
            id4: makeMetadata(id: id4, category: .scenery),
        ]

        let days = TimelineGenerator.generate(clusters: [laterCluster, earlierCluster], metadata: metadata)
        #expect(days.count == 1)
        let nonGapEvents = days[0].events.filter { !$0.isTravelGap }
        #expect(nonGapEvents.count == 2)
        #expect(nonGapEvents[0].startTime < nonGapEvents[1].startTime)
    }

    @Test("gap over 2 hours inserts travel marker")
    func travelGap() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID(), id4 = UUID()

        let morning = makeCluster(ids: [id1, id2], startOffset: 0, duration: 600)
        let evening = makeCluster(ids: [id3, id4], startOffset: 10 * 3600, duration: 600)

        let metadata: [UUID: PhotoMetadata] = [
            id1: makeMetadata(id: id1, category: .food),
            id2: makeMetadata(id: id2, category: .food),
            id3: makeMetadata(id: id3, category: .landmark),
            id4: makeMetadata(id: id4, category: .landmark),
        ]

        let days = TimelineGenerator.generate(clusters: [morning, evening], metadata: metadata)
        #expect(days.count == 1)
        let gapEvents = days[0].events.filter { $0.isTravelGap }
        #expect(gapEvents.count == 1)
        #expect(gapEvents[0].photoCount == 0)
    }

    @Test("no travel marker for gap under 2 hours")
    func noGapUnderThreshold() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID(), id4 = UUID()

        let first = makeCluster(ids: [id1, id2], startOffset: 0, duration: 600)
        let second = makeCluster(ids: [id3, id4], startOffset: 3600, duration: 600)

        let metadata: [UUID: PhotoMetadata] = [
            id1: makeMetadata(id: id1, category: .food),
            id2: makeMetadata(id: id2, category: .food),
            id3: makeMetadata(id: id3, category: .food),
            id4: makeMetadata(id: id4, category: .food),
        ]

        let days = TimelineGenerator.generate(clusters: [first, second], metadata: metadata)
        let gapEvents = days[0].events.filter { $0.isTravelGap }
        #expect(gapEvents.isEmpty)
    }
}

@Suite("Dominant Category Tests")
struct DominantCategoryTests {
    @Test("most common category wins")
    func mostCommon() {
        let result = TimelineGenerator.dominantCategory([.food, .food, .scenery])
        #expect(result == .food)
    }

    @Test("empty categories default to activity")
    func emptyDefault() {
        let result = TimelineGenerator.dominantCategory([])
        #expect(result == .activity)
    }

    @Test("single category returns that category")
    func singleCategory() {
        let result = TimelineGenerator.dominantCategory([.landmark])
        #expect(result == .landmark)
    }
}

@Suite("Timeline Day Grouping Tests")
struct TimelineDayGroupingTests {
    @Test("empty clusters produce empty days")
    func emptyClusters() {
        let days = TimelineGenerator.generate(clusters: [], metadata: [:])
        #expect(days.isEmpty)
    }

    @Test("photo count sums non-gap events")
    func photoCountSum() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID()
        let cluster = makeCluster(ids: [id1, id2, id3], startOffset: 0, duration: 600)
        let metadata: [UUID: PhotoMetadata] = [
            id1: makeMetadata(id: id1, category: .food),
            id2: makeMetadata(id: id2, category: .food),
            id3: makeMetadata(id: id3, category: .food),
        ]
        let days = TimelineGenerator.generate(clusters: [cluster], metadata: metadata)
        #expect(days[0].photoCount == 3)
    }

    @Test("member contributions counted correctly")
    func memberContributions() {
        let id1 = UUID(), id2 = UUID(), id3 = UUID()
        let memberA = UUID(), memberB = UUID()
        let cluster = makeCluster(ids: [id1, id2, id3], startOffset: 0, duration: 600)
        let metadata: [UUID: PhotoMetadata] = [
            id1: makeMetadata(id: id1, category: .food, memberId: memberA),
            id2: makeMetadata(id: id2, category: .food, memberId: memberA),
            id3: makeMetadata(id: id3, category: .food, memberId: memberB),
        ]
        let days = TimelineGenerator.generate(clusters: [cluster], metadata: metadata)
        let event = days[0].events.first { !$0.isTravelGap }!
        #expect(event.memberContributions[memberA] == 2)
        #expect(event.memberContributions[memberB] == 1)
    }
}
