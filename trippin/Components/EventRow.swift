//
//  EventRow.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct EventRow: View {
    let event: TimelineEvent
    let assetIds: [String]
    let members: [TripMember]
    var localTimezone: TimeZone = .current

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = localTimezone
        return f
    }

    private var categoryIcon: String {
        switch event.dominantCategory {
        case .food: "fork.knife"
        case .scenery: "mountain.2"
        case .landmark: "building.columns"
        case .activity: "figure.walk"
        case .people: "person.2"
        case .miscellaneous: "square.grid.2x2"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(spacing: Spacing.xxxs) {
                Circle()
                    .fill(Color.paperSecondary)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 20)
            .padding(.top, Spacing.xs)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.paperSecondary)

                    Text(timeRange)
                        .font(.paperMono(12))
                        .foregroundStyle(Color.paperTextSecondary)

                    Spacer()

                    Text("\(event.photoCount)")
                        .font(.paperMono(12))
                        .foregroundStyle(Color.paperTextSecondary)
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.paperTextSecondary)
                }

                if !assetIds.isEmpty {
                    thumbnailStrip
                }

                if !contributingMembers.isEmpty {
                    memberBadges
                }
            }
            .paperCard(padding: Spacing.sm)
        }
        .padding(.leading, Spacing.md)
        .padding(.trailing, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.dominantCategory.rawValue) event, \(timeRange), \(event.photoCount) photos")
    }

    private var timeRange: String {
        if event.photoCount <= 1 || event.startTime == event.endTime {
            return timeFormatter.string(from: event.startTime)
        }
        return "\(timeFormatter.string(from: event.startTime)) – \(timeFormatter.string(from: event.endTime))"
    }

    private var thumbnailStrip: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(Array(assetIds.prefix(4).enumerated()), id: \.offset) { _, assetId in
                AsyncThumbnail(localIdentifier: assetId)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }
            if assetIds.count > 4 {
                Text("+\(assetIds.count - 4)")
                    .font(.paperMono(12))
                    .foregroundStyle(Color.paperTextSecondary)
                    .frame(width: 56, height: 56)
                    .background(Color.paperBorder.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }
        }
    }

    private var contributingMembers: [TripMember] {
        members.filter { event.memberContributions[$0.id] != nil }
    }

    private var memberBadges: some View {
        HStack(spacing: -Spacing.xxs) {
            ForEach(contributingMembers.prefix(5)) { member in
                Circle()
                    .fill(Color(hex: member.color))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(member.emoji)
                            .font(.system(size: 10))
                    )
                    .overlay(
                        Circle().stroke(Color.paperSurface, lineWidth: 1.5)
                    )
            }
        }
    }
}

struct AsyncThumbnail: View {
    let localIdentifier: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.paperBorder.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            }
        }
        .task {
            image = await PhotoAssetLoader.loadThumbnail(localIdentifier: localIdentifier, size: CGSize(width: 112, height: 112))
        }
    }
}
