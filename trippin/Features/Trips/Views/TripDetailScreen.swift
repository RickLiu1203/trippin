//
//  TripDetailScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct TripDetailScreen: View {
    @State private var viewModel: TripDetailViewModel
    @Environment(AppRouter.self) private var router
    @Environment(AuthViewModel.self) private var authViewModel

    init(tripId: UUID) {
        _viewModel = State(initialValue: TripDetailViewModel(tripId: tripId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let trip = viewModel.trip {
                tripContent(trip)
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn't load trip",
                    message: viewModel.error ?? "Something went wrong",
                    actionTitle: "Retry"
                ) {
                    Task { await viewModel.loadTrip() }
                }
            }
        }
        .background(Color.paperSurface)
        .navigationTitle(viewModel.trip?.name ?? "Trip")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share trip")

                Button {
                    viewModel.showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit trip")
            }
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            if let trip = viewModel.trip {
                EditTripScreen(
                    tripId: trip.id,
                    currentName: trip.name,
                    albumIdentifier: trip.albumIdentifier
                ) {
                    Task { await viewModel.loadTrip() }
                }
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let trip = viewModel.trip {
                ShareTripSheet(shareCode: trip.shareCode)
            }
        }
        .sheet(isPresented: $viewModel.showLinkAlbumSheet) {
            LinkAlbumSheet { albumId in
                Task { await viewModel.linkAlbum(albumId) }
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .task {
            if case .signedIn(let userId) = authViewModel.state {
                viewModel.userId = userId
            }
            await viewModel.loadTrip()
        }
    }

    private func tripContent(_ trip: Trip) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                albumSection(trip)
                timelinePlaceholder
                TripDetailMembersSection(
                    members: viewModel.members,
                    isOwner: viewModel.isOwner,
                    onRemove: { member in
                        Task { await viewModel.removeMember(member) }
                    }
                )
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }

    @ViewBuilder
    private func albumSection(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Album")
                .font(.paperBody(14, weight: .medium))
                .foregroundStyle(Color.paperTextSecondary)

            if let album = viewModel.linkedAlbum {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(Color.paperSuccess)
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(album.title)
                            .font(.paperBody(16, weight: .medium))
                            .foregroundStyle(Color.paperText)
                        Text("\(album.assetCount) photos")
                            .font(.paperBody(14))
                            .foregroundStyle(Color.paperTextSecondary)
                    }
                    Spacer()
                    Button("Change") {
                        viewModel.showLinkAlbumSheet = true
                    }
                    .font(.paperBody(14, weight: .medium))
                    .foregroundStyle(Color.paperSecondary)
                }
                .paperCard()
            } else if trip.albumIdentifier != nil {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(Color.paperTextSecondary)
                    Text("Album linked")
                        .font(.paperBody())
                        .foregroundStyle(Color.paperText)
                    Spacer()
                    Button("Change") {
                        viewModel.showLinkAlbumSheet = true
                    }
                    .font(.paperBody(14, weight: .medium))
                    .foregroundStyle(Color.paperSecondary)
                }
                .paperCard()
            } else {
                Button {
                    viewModel.showLinkAlbumSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Link iCloud Shared Album")
                            .font(.paperBody(16, weight: .medium))
                    }
                    .foregroundStyle(Color.paperSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
                .paperCard()
                .accessibilityLabel("Link album")
                .accessibilityHint("Double tap to select a shared album for this trip")
            }
        }
    }

    private var timelinePlaceholder: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "calendar.day.timeline.leading")
                .font(.system(size: 32))
                .foregroundStyle(Color.paperTextSecondary)
            Text("Timeline")
                .font(.paperBody(16, weight: .medium))
                .foregroundStyle(Color.paperText)
            Text("Link an album and process photos to build your trip timeline")
                .font(.paperBody(14))
                .foregroundStyle(Color.paperTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .paperCard()
    }
}
