//
//  EventDetailScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct EventDetailScreen: View {
    @State private var viewModel: EventDetailViewModel

    init(event: TimelineEvent, photos: [PhotoMetadata], members: [TripMember]) {
        _viewModel = State(initialValue: EventDetailViewModel(
            event: event,
            photos: photos,
            members: members
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                headerSection

                if !viewModel.assetIds.isEmpty {
                    photoGrid
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.paperSurface)
        .navigationTitle(viewModel.event.dominantCategory.rawValue.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: categoryIcon)
                    .foregroundStyle(Color.paperSecondary)
                Text(viewModel.event.dominantCategory.rawValue.capitalized)
                    .font(.paperDisplay(20, weight: .semibold))
                    .foregroundStyle(Color.paperText)
            }

            Text(viewModel.timeRange)
                .font(.paperMono(14))
                .foregroundStyle(Color.paperTextSecondary)

            Text("\(viewModel.event.photoCount) photos")
                .font(.paperBody(14))
                .foregroundStyle(Color.paperTextSecondary)
        }
    }

    private var photoGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.xxs),
            GridItem(.flexible(), spacing: Spacing.xxs),
            GridItem(.flexible(), spacing: Spacing.xxs),
        ], spacing: Spacing.xxs) {
            ForEach(viewModel.assetIds, id: \.self) { assetId in
                AsyncThumbnail(localIdentifier: assetId)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }
        }
    }

    private var categoryIcon: String {
        switch viewModel.event.dominantCategory {
        case .food: "fork.knife"
        case .scenery: "mountain.2"
        case .landmark: "building.columns"
        case .activity: "figure.walk"
        case .people: "person.2"
        case .miscellaneous: "square.grid.2x2"
        }
    }
}
