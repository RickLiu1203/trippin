//
//  TripDetailTimelineSection.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct TripDetailTimelineSection: View {
    let days: [TimelineDay]
    let members: [TripMember]
    let metadataByPhotoId: [UUID: PhotoMetadata]
    let onEventTap: (UUID) -> Void
    @State private var selectedDay: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if days.count > 1 {
                dayPicker
            }

            if let day = days.first(where: { $0.dayIndex == selectedDay }) ?? days.first {
                dayContent(day)
            }
        }
    }

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(days) { day in
                    Button {
                        selectedDay = day.dayIndex
                    } label: {
                        Text("Day \(day.dayIndex + 1)")
                            .font(.paperBody(14, weight: selectedDay == day.dayIndex ? .semibold : .regular))
                            .foregroundStyle(selectedDay == day.dayIndex ? Color.paperPrimary : Color.paperTextSecondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                selectedDay == day.dayIndex
                                    ? Color.paperPrimary.opacity(0.1)
                                    : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Day \(day.dayIndex + 1), \(day.photoCount) photos")
                    .accessibilityAddTraits(selectedDay == day.dayIndex ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }

    private func timezoneForDay(_ day: TimelineDay) -> TimeZone {
        let firstLon = day.events.first(where: { !$0.isTravelGap })?.centroidLon
        return PhotoKitEXIFExtractor.timezoneFromLongitude(firstLon)
    }

    private func dayContent(_ day: TimelineDay) -> some View {
        let tz = timezoneForDay(day)
        return VStack(alignment: .leading, spacing: 0) {
            DayCard(day: day, localTimezone: tz)

            ForEach(Array(day.events.enumerated()), id: \.element.id) { index, event in
                if event.isTravelGap {
                    TimelineConnector(isTravelGap: true)
                } else {
                    if index > 0 && !day.events[index - 1].isTravelGap {
                        TimelineConnector()
                    }

                    Button {
                        onEventTap(event.id)
                    } label: {
                        EventRow(
                            event: event,
                            assetIds: assetIdsForEvent(event),
                            members: members,
                            localTimezone: tz
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func assetIdsForEvent(_ event: TimelineEvent) -> [String] {
        event.photoMetadataIds.compactMap { metadataByPhotoId[$0]?.localAssetId }
    }
}
