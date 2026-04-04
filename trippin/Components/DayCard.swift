//
//  DayCard.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct DayCard: View {
    let day: TimelineDay

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Day \(day.dayIndex + 1)")
                    .font(.paperDisplay(18, weight: .semibold))
                    .foregroundStyle(Color.paperText)
                Text(dateFormatter.string(from: day.date))
                    .font(.paperBody(14))
                    .foregroundStyle(Color.paperTextSecondary)
            }
            Spacer()
            Text("\(day.photoCount) photos")
                .font(.paperMono(14))
                .foregroundStyle(Color.paperTextSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Day \(day.dayIndex + 1), \(dateFormatter.string(from: day.date)), \(day.photoCount) photos")
    }
}
