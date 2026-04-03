//
//  TripCard.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct TripCard: View {
    let trip: Trip
    let members: [TripMember]
    let photoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(trip.name)
                .font(.paperDisplay(18, weight: .semibold))
                .foregroundStyle(Color.paperText)
                .lineLimit(2)

            HStack(spacing: Spacing.sm) {
                if !members.isEmpty {
                    MemberAvatarStack(members: members)
                }

                Spacer()

                if photoCount > 0 {
                    Label("\(photoCount)", systemImage: "photo")
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperTextSecondary)
                }
            }
        }
        .paperCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.name), \(members.count) member\(members.count == 1 ? "" : "s"), \(photoCount) photo\(photoCount == 1 ? "" : "s")")
        .accessibilityHint("Double tap to open trip")
    }
}
