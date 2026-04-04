//
//  DBSCANClustererTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

private func makePoint(lat: Double, lon: Double, minutesOffset: Double = 0) -> PhotoPoint {
    PhotoPoint(
        id: UUID(),
        latitude: lat,
        longitude: lon,
        takenAt: baseDate.addingTimeInterval(minutesOffset * 60)
    )
}

@Suite("Haversine Distance Tests")
struct HaversineDistanceTests {
    @Test("same point returns zero")
    func samePoint() {
        let d = HaversineDistance.meters(lat1: 35.6812, lon1: 139.7671, lat2: 35.6812, lon2: 139.7671)
        #expect(d < 0.01)
    }

    @Test("Tokyo Station to Shibuya is roughly 6.4km")
    func tokyoToShibuya() {
        let d = HaversineDistance.meters(lat1: 35.6812, lon1: 139.7671, lat2: 35.6580, lon2: 139.7016)
        #expect(d > 6000 && d < 7000)
    }

    @Test("equator one degree longitude is roughly 111km")
    func equatorOneDegree() {
        let d = HaversineDistance.meters(lat1: 0, lon1: 0, lat2: 0, lon2: 1)
        #expect(d > 110_000 && d < 112_000)
    }

    @Test("New York to London is roughly 5570km")
    func newYorkToLondon() {
        let d = HaversineDistance.meters(lat1: 40.7128, lon1: -74.0060, lat2: 51.5074, lon2: -0.1278)
        #expect(d > 5_500_000 && d < 5_700_000)
    }
}

@Suite("DBSCAN Clustering Tests")
struct DBSCANClusteringTests {
    @Test("empty input returns empty output")
    func emptyInput() {
        let clusterer = DBSCANClusterer()
        let result = clusterer.cluster([])
        #expect(result.isEmpty)
    }

    @Test("single point becomes single-photo cluster")
    func singlePoint() {
        let clusterer = DBSCANClusterer()
        let result = clusterer.cluster([makePoint(lat: 35.68, lon: 139.77)])
        #expect(result.count == 1)
        #expect(result[0].points.count == 1)
    }

    @Test("three distinct location groups produce three clusters")
    func threeGroups() {
        let clusterer = DBSCANClusterer(epsMeters: 50, epsMinutes: 30, minPoints: 2)

        let points = [
            makePoint(lat: 35.6812, lon: 139.7671, minutesOffset: 0),
            makePoint(lat: 35.6813, lon: 139.7672, minutesOffset: 5),
            makePoint(lat: 35.6580, lon: 139.7016, minutesOffset: 60),
            makePoint(lat: 35.6581, lon: 139.7017, minutesOffset: 65),
            makePoint(lat: 35.7100, lon: 139.8100, minutesOffset: 120),
            makePoint(lat: 35.7101, lon: 139.8101, minutesOffset: 125),
        ]

        let result = clusterer.cluster(points)
        #expect(result.count == 3)
    }

    @Test("same location more than 30min apart produces separate clusters")
    func timeSplit() {
        let clusterer = DBSCANClusterer(epsMeters: 50, epsMinutes: 30, minPoints: 2)

        let points = [
            makePoint(lat: 35.6812, lon: 139.7671, minutesOffset: 0),
            makePoint(lat: 35.6812, lon: 139.7671, minutesOffset: 10),
            makePoint(lat: 35.6812, lon: 139.7671, minutesOffset: 60),
            makePoint(lat: 35.6812, lon: 139.7671, minutesOffset: 70),
        ]

        let result = clusterer.cluster(points)
        #expect(result.count == 2)
    }

    @Test("different locations within 50m form same cluster")
    func nearbyLocations() {
        let clusterer = DBSCANClusterer(epsMeters: 50, epsMinutes: 30, minPoints: 2)

        let points = [
            makePoint(lat: 35.681200, lon: 139.767100, minutesOffset: 0),
            makePoint(lat: 35.681230, lon: 139.767130, minutesOffset: 5),
            makePoint(lat: 35.681260, lon: 139.767160, minutesOffset: 10),
        ]

        let result = clusterer.cluster(points)
        #expect(result.count == 1)
        #expect(result[0].points.count == 3)
    }

    @Test("isolated photo becomes noise then single-photo cluster")
    func isolatedPoint() {
        let clusterer = DBSCANClusterer(epsMeters: 50, epsMinutes: 30, minPoints: 2)

        let points = [
            makePoint(lat: 35.6812, lon: 139.7671, minutesOffset: 0),
            makePoint(lat: 35.6813, lon: 139.7672, minutesOffset: 5),
            makePoint(lat: 40.7128, lon: -74.0060, minutesOffset: 500),
        ]

        let result = clusterer.cluster(points)
        let singleClusters = result.filter { $0.points.count == 1 }
        let multiClusters = result.filter { $0.points.count > 1 }
        #expect(singleClusters.count == 1)
        #expect(multiClusters.count == 1)
    }

    @Test("clusters are sorted chronologically")
    func chronologicalOrder() {
        let clusterer = DBSCANClusterer(epsMeters: 50, epsMinutes: 30, minPoints: 2)

        let points = [
            makePoint(lat: 35.6812, lon: 139.7671, minutesOffset: 100),
            makePoint(lat: 35.6813, lon: 139.7672, minutesOffset: 105),
            makePoint(lat: 35.6580, lon: 139.7016, minutesOffset: 0),
            makePoint(lat: 35.6581, lon: 139.7017, minutesOffset: 5),
        ]

        let result = clusterer.cluster(points)
        #expect(result.count == 2)
        #expect(result[0].startTime < result[1].startTime)
    }

    @Test("centroid is average of cluster points")
    func centroidCalculation() {
        let clusterer = DBSCANClusterer(epsMeters: 100, epsMinutes: 30, minPoints: 2)

        let points = [
            makePoint(lat: 10.0, lon: 20.0, minutesOffset: 0),
            makePoint(lat: 10.0002, lon: 20.0002, minutesOffset: 5),
        ]

        let result = clusterer.cluster(points)
        #expect(result.count == 1)
        #expect(abs(result[0].centroidLat - 10.0001) < 0.001)
        #expect(abs(result[0].centroidLon - 20.0001) < 0.001)
    }
}

@Suite("DBSCAN Day Splitting Tests")
struct DBSCANDaySplitTests {
    @Test("cluster spanning midnight is split into two")
    func midnightSplit() {
        let clusterer = DBSCANClusterer(epsMeters: 100, epsMinutes: 1440, minPoints: 2)

        let cal = Calendar(identifier: .gregorian)
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 3
        comps.day = 15
        comps.hour = 23
        comps.minute = 30
        comps.timeZone = TimeZone(identifier: "UTC")
        let beforeMidnight = cal.date(from: comps)!

        comps.day = 16
        comps.hour = 0
        comps.minute = 30
        let afterMidnight = cal.date(from: comps)!

        let points = [
            PhotoPoint(id: UUID(), latitude: 0, longitude: 0, takenAt: beforeMidnight),
            PhotoPoint(id: UUID(), latitude: 0, longitude: 0, takenAt: afterMidnight),
        ]

        let result = clusterer.clusterWithDaySplit(points)
        #expect(result.count == 2)
    }

    @Test("cluster within single day is not split")
    func singleDay() {
        let clusterer = DBSCANClusterer(epsMeters: 100, epsMinutes: 60, minPoints: 2)

        let points = [
            makePoint(lat: 10.0, lon: 0.0, minutesOffset: 0),
            makePoint(lat: 10.0, lon: 0.0, minutesOffset: 30),
        ]

        let result = clusterer.clusterWithDaySplit(points)
        #expect(result.count == 1)
        #expect(result[0].points.count == 2)
    }
}

@Suite("DBSCAN Performance Tests")
struct DBSCANPerformanceTests {
    @Test("500 points completes without timeout")
    func fiveHundredPoints() {
        let clusterer = DBSCANClusterer(epsMeters: 50, epsMinutes: 30, minPoints: 2)

        var points: [PhotoPoint] = []
        for i in 0..<500 {
            let groupIndex = i / 10
            let baseLat = 35.68 + Double(groupIndex) * 0.01
            let baseLon = 139.77 + Double(groupIndex) * 0.01
            points.append(makePoint(
                lat: baseLat + Double.random(in: -0.0001...0.0001),
                lon: baseLon + Double.random(in: -0.0001...0.0001),
                minutesOffset: Double(groupIndex) * 60 + Double(i % 10) * 2
            ))
        }

        let result = clusterer.cluster(points)
        #expect(!result.isEmpty)
        #expect(result.count <= 500)
    }
}
