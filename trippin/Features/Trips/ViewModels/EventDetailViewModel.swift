//
//  EventDetailViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class EventDetailViewModel {
    let event: TimelineEvent
    let photos: [PhotoMetadata]
    let members: [TripMember]

    init(event: TimelineEvent, photos: [PhotoMetadata], members: [TripMember]) {
        self.event = event
        self.photos = photos
        self.members = members
    }

    var assetIds: [String] {
        photos.map(\.localAssetId)
    }

    var localTimezone: TimeZone {
        PhotoKitEXIFExtractor.timezoneFromLongitude(event.centroidLon)
    }

    var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = localTimezone
        return f
    }

    var timeRange: String {
        if event.photoCount <= 1 || event.startTime == event.endTime {
            return timeFormatter.string(from: event.startTime)
        }
        return "\(timeFormatter.string(from: event.startTime)) – \(timeFormatter.string(from: event.endTime))"
    }
}
