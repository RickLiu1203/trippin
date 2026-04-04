//
//  DayCard.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct DayCard: View {
    let day: TimelineDay
    let localTimezone: TimeZone

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        f.timeZone = localTimezone
        return f
    }

    private var gmtOffset: String {
        let seconds = localTimezone.secondsFromGMT()
        let hours = seconds / 3600
        let sign = hours >= 0 ? "+" : ""
        return "GMT\(sign)\(hours)"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Day \(day.dayIndex + 1)")
                    .font(.paperDisplay(18, weight: .semibold))
                    .foregroundStyle(Color.paperText)
                HStack(spacing: Spacing.xs) {
                    Text(dateFormatter.string(from: day.date))
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperTextSecondary)
                    Text(gmtOffset)
                        .font(.paperMono(12))
                        .foregroundStyle(Color.paperTextSecondary.opacity(0.7))
                }
            }
            Spacer()
            Text("\(day.photoCount) photos")
                .font(.paperMono(14))
                .foregroundStyle(Color.paperTextSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Day \(day.dayIndex + 1), \(dateFormatter.string(from: day.date)), \(gmtOffset), \(day.photoCount) photos")
    }
}
