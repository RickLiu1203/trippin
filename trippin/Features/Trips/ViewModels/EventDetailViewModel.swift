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

    var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }

    var timeRange: String {
        "\(timeFormatter.string(from: event.startTime)) – \(timeFormatter.string(from: event.endTime))"
    }
}
