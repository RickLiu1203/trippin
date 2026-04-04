//
//  DBSCANClusterer.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct PhotoPoint: Sendable, Equatable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let takenAt: Date
}

struct ClusterResult: Sendable {
    let points: [PhotoPoint]
    let centroidLat: Double
    let centroidLon: Double
    let startTime: Date
    let endTime: Date
}

final class DBSCANClusterer: Sendable {
    let epsMeters: Double
    let epsMinutes: Double
    let minPoints: Int

    init(epsMeters: Double = 50, epsMinutes: Double = 30, minPoints: Int = 2) {
        self.epsMeters = epsMeters
        self.epsMinutes = epsMinutes
        self.minPoints = minPoints
    }

    func cluster(_ points: [PhotoPoint]) -> [ClusterResult] {
        guard !points.isEmpty else { return [] }

        var labels = [Int](repeating: -1, count: points.count)
        var clusterIndex = 0

        for i in 0..<points.count {
            if labels[i] != -1 { continue }

            let neighbors = rangeQuery(points: points, index: i)
            if neighbors.count < minPoints {
                labels[i] = 0
            } else {
                clusterIndex += 1
                labels[i] = clusterIndex

                var seedSet = Set(neighbors)
                seedSet.remove(i)

                while !seedSet.isEmpty {
                    let j = seedSet.removeFirst()
                    if labels[j] == 0 { labels[j] = clusterIndex }
                    if labels[j] != -1 { continue }
                    labels[j] = clusterIndex

                    let jNeighbors = rangeQuery(points: points, index: j)
                    if jNeighbors.count >= minPoints {
                        seedSet.formUnion(jNeighbors)
                    }
                }
            }
        }

        return buildClusters(points: points, labels: labels, maxCluster: clusterIndex)
    }

    func clusterWithDaySplit(_ points: [PhotoPoint]) -> [ClusterResult] {
        cluster(points).flatMap { splitByDay($0) }
    }

    func isNeighbor(_ a: PhotoPoint, _ b: PhotoPoint) -> Bool {
        let spaceDist = HaversineDistance.meters(
            lat1: a.latitude, lon1: a.longitude,
            lat2: b.latitude, lon2: b.longitude
        )
        let timeDist = abs(a.takenAt.timeIntervalSince(b.takenAt)) / 60

        return max(spaceDist / epsMeters, timeDist / epsMinutes) <= 1.0
    }

    private func rangeQuery(points: [PhotoPoint], index: Int) -> [Int] {
        let p = points[index]
        var neighbors: [Int] = []
        for j in 0..<points.count {
            if isNeighbor(p, points[j]) {
                neighbors.append(j)
            }
        }
        return neighbors
    }

    private func buildClusters(points: [PhotoPoint], labels: [Int], maxCluster: Int) -> [ClusterResult] {
        var clusters: [ClusterResult] = []

        for c in 1...max(maxCluster, 1) {
            let clusterPoints = zip(points, labels).filter { $0.1 == c }.map(\.0)
            if !clusterPoints.isEmpty {
                clusters.append(makeCluster(from: clusterPoints))
            }
        }

        for (point, label) in zip(points, labels) where label == 0 {
            clusters.append(makeCluster(from: [point]))
        }

        return clusters.sorted { $0.startTime < $1.startTime }
    }

    private func makeCluster(from points: [PhotoPoint]) -> ClusterResult {
        let sorted = points.sorted { $0.takenAt < $1.takenAt }
        return ClusterResult(
            points: sorted,
            centroidLat: points.reduce(0.0) { $0 + $1.latitude } / Double(points.count),
            centroidLon: points.reduce(0.0) { $0 + $1.longitude } / Double(points.count),
            startTime: sorted.first!.takenAt,
            endTime: sorted.last!.takenAt
        )
    }

    private func splitByDay(_ cluster: ClusterResult) -> [ClusterResult] {
        let offsetHours = Int(round(cluster.centroidLon / 15.0))
        let timezone = TimeZone(secondsFromGMT: offsetHours * 3600) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone

        var dayGroups: [Int: [PhotoPoint]] = [:]
        for point in cluster.points {
            let year = calendar.component(.year, from: point.takenAt)
            let day = calendar.ordinality(of: .day, in: .year, for: point.takenAt) ?? 0
            dayGroups[year * 1000 + day, default: []].append(point)
        }

        if dayGroups.count <= 1 { return [cluster] }

        return dayGroups.keys.sorted().compactMap { key in
            guard let points = dayGroups[key], !points.isEmpty else { return nil }
            return makeCluster(from: points)
        }
    }
}
