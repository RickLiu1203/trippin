//
//  TimelineGenerator.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation

struct TimelineDay: Sendable, Identifiable {
    var id: Int { dayIndex }
    let dayIndex: Int
    let date: Date
    let events: [TimelineEvent]

    var photoCount: Int {
        events.filter { !$0.isTravelGap }.reduce(0) { $0 + $1.photoCount }
    }
}

struct TimelineEvent: Sendable, Identifiable {
    let id: UUID
    let isTravelGap: Bool
    let startTime: Date
    let endTime: Date
    let photoCount: Int
    let dominantCategory: PhotoCategory
    let memberContributions: [UUID: Int]
    let photoMetadataIds: [UUID]
    let centroidLat: Double?
    let centroidLon: Double?
}

enum TimelineGenerator {
    static let travelGapThreshold: TimeInterval = 2 * 60 * 60

    static func generateFromDB(
        clusters: [PhotoCluster],
        clusterPhotos: [ClusterPhoto],
        metadata: [PhotoMetadata]
    ) -> [TimelineDay] {
        let metadataById = Dictionary(uniqueKeysWithValues: metadata.map { ($0.id, $0) })
        let photosByCluster = Dictionary(grouping: clusterPhotos, by: \.clusterId)

        let events: [TimelineEvent] = clusters.map { cluster in
            let photoIds = photosByCluster[cluster.id]?.map(\.photoMetadataId) ?? []
            let categories = photoIds.compactMap { metadataById[$0]?.category }
            let dominant = dominantCategory(categories)

            var memberCounts: [UUID: Int] = [:]
            for id in photoIds {
                if let memberId = metadataById[id]?.memberId {
                    memberCounts[memberId, default: 0] += 1
                }
            }

            return TimelineEvent(
                id: cluster.id,
                isTravelGap: false,
                startTime: cluster.startTime,
                endTime: cluster.endTime,
                photoCount: cluster.photoCount,
                dominantCategory: dominant,
                memberContributions: memberCounts,
                photoMetadataIds: photoIds,
                centroidLat: cluster.centroidLat,
                centroidLon: cluster.centroidLon
            )
        }

        let sorted = events.sorted { $0.startTime < $1.startTime }
        let withGaps = insertTravelGaps(events: sorted)
        return groupByDay(events: withGaps)
    }

    static func generate(
        clusters: [ClusterResult],
        metadata: [UUID: PhotoMetadata]
    ) -> [TimelineDay] {
        let events = clusters
            .map { makeEvent(from: $0, metadata: metadata) }
            .sorted { $0.startTime < $1.startTime }

        let eventsWithGaps = insertTravelGaps(events: events)
        return groupByDay(events: eventsWithGaps)
    }

    static func makeEvent(
        from cluster: ClusterResult,
        metadata: [UUID: PhotoMetadata]
    ) -> TimelineEvent {
        let photoIds = cluster.points.map(\.id)
        let categories = photoIds.compactMap { metadata[$0]?.category }
        let dominant = dominantCategory(categories)

        var memberCounts: [UUID: Int] = [:]
        for id in photoIds {
            if let memberId = metadata[id]?.memberId {
                memberCounts[memberId, default: 0] += 1
            }
        }

        return TimelineEvent(
            id: UUID(),
            isTravelGap: false,
            startTime: cluster.startTime,
            endTime: cluster.endTime,
            photoCount: cluster.points.count,
            dominantCategory: dominant,
            memberContributions: memberCounts,
            photoMetadataIds: photoIds,
            centroidLat: cluster.centroidLat,
            centroidLon: cluster.centroidLon
        )
    }

    static func dominantCategory(_ categories: [PhotoCategory]) -> PhotoCategory {
        guard !categories.isEmpty else { return .activity }
        if categories.contains(.food) { return .food }
        var counts: [PhotoCategory: Int] = [:]
        for cat in categories { counts[cat, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? .activity
    }

    static func insertTravelGaps(events: [TimelineEvent]) -> [TimelineEvent] {
        guard events.count > 1 else { return events }
        var result: [TimelineEvent] = [events[0]]
        for i in 1..<events.count {
            let prev = events[i - 1]
            let curr = events[i]
            let gap = curr.startTime.timeIntervalSince(prev.endTime)
            if gap > travelGapThreshold {
                result.append(TimelineEvent(
                    id: UUID(),
                    isTravelGap: true,
                    startTime: prev.endTime,
                    endTime: curr.startTime,
                    photoCount: 0,
                    dominantCategory: .activity,
                    memberContributions: [:],
                    photoMetadataIds: [],
                    centroidLat: nil,
                    centroidLon: nil
                ))
            }
            result.append(curr)
        }
        return result
    }

    static func groupByDay(events: [TimelineEvent]) -> [TimelineDay] {
        guard let firstEvent = events.first(where: { !$0.isTravelGap }) else { return [] }

        let tripTimezone = PhotoKitEXIFExtractor.timezoneFromLongitude(firstEvent.centroidLon)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tripTimezone

        let startOfFirstDay = calendar.startOfDay(for: firstEvent.startTime)

        var dayMap: [Int: [TimelineEvent]] = [:]
        for event in events {
            let dayIndex = calendar.dateComponents(
                [.day],
                from: startOfFirstDay,
                to: calendar.startOfDay(for: event.startTime)
            ).day ?? 0
            dayMap[dayIndex, default: []].append(event)
        }

        return dayMap.keys.sorted().map { dayIndex in
            let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: startOfFirstDay) ?? startOfFirstDay
            return TimelineDay(
                dayIndex: dayIndex,
                date: dayDate,
                events: dayMap[dayIndex] ?? []
            )
        }
    }
}
