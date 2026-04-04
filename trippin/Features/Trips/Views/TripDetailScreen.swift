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
    @State private var selectedEvent: TimelineEvent?

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
                EditTripScreen(tripId: trip.id, currentName: trip.name) {
                    Task { await viewModel.loadTrip() }
                }
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let trip = viewModel.trip {
                ShareTripSheet(shareCode: trip.shareCode)
            }
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                EventDetailScreen(
                    event: event,
                    photos: viewModel.photosForEvent(event),
                    members: viewModel.members
                )
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
                processingBanner

                if viewModel.timelineDays.isEmpty && !isProcessing {
                    timelinePlaceholder
                } else {
                    TripDetailTimelineSection(
                        days: viewModel.timelineDays,
                        members: viewModel.members,
                        metadataByPhotoId: viewModel.metadataById,
                        onEventTap: { eventId in
                            selectedEvent = viewModel.eventById(eventId)
                        }
                    )
                }

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

    private var isProcessing: Bool {
        if case .processing = viewModel.processingState { return true }
        return false
    }

    @ViewBuilder
    private var processingBanner: some View {
        switch viewModel.processingState {
        case .processing(let completed, let total):
            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                if total > 0 {
                    Text("Processing \(completed)/\(total) photos...")
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperTextSecondary)
                } else {
                    Text("Scanning album...")
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperTextSecondary)
                }
                Spacer()
            }
            .padding(Spacing.sm)
            .background(Color.paperSecondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        case .complete, .idle:
            syncStatusBanner
        case .error(let msg):
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.paperDanger)
                Text(msg)
                    .font(.paperBody(14))
                    .foregroundStyle(Color.paperText)
                    .lineLimit(2)
                Spacer()
            }
            .padding(Spacing.sm)
            .background(Color.paperDanger.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var syncStatusBanner: some View {
        if viewModel.waitingDeviceCount > 0 {
            let n = viewModel.waitingDeviceCount
            let w = viewModel.waitingPhotoCount
            HStack(spacing: Spacing.xs) {
                Image(systemName: "person.crop.circle.badge.clock")
                    .foregroundStyle(Color.paperWarning)
                Text("Synced \(viewModel.syncedPhotoCount) photos \u{00B7} waiting on \(n) \(n == 1 ? "person" : "people") (\(w) photos)")
                    .font(.paperBody(13))
                    .foregroundStyle(Color.paperText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(Color.paperWarning.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
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
            Text("Processing photos to build your trip timeline...")
                .font(.paperBody(14))
                .foregroundStyle(Color.paperTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .paperCard()
    }
}
