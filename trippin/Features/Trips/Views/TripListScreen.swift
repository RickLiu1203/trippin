//
//  TripListScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct TripListScreen: View {
    @State private var viewModel = TripListViewModel()
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.trips.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.trips.isEmpty {
                EmptyStateView(
                    icon: "suitcase",
                    title: "No trips yet",
                    message: "Select an album to create your first trip",
                    actionTitle: "New Trip"
                ) {
                    viewModel.showCreateSheet = true
                }
            } else {
                tripList
            }
        }
        .background(Color.paperSurface)
        .navigationTitle("Trips")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.paperPrimary)
                }
                .accessibilityLabel("New trip")
                .accessibilityHint("Double tap to select an album and create a trip")
            }
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateTripSheet(linkedAlbumIds: viewModel.linkedAlbumIds) { album in
                Task {
                    if let tripId = await viewModel.createTripFromAlbum(album) {
                        router.navigate(to: .tripDetail(tripId: tripId))
                    }
                }
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
            await viewModel.loadTrips()
            handlePendingShareCode()
        }
        .onAppear {
            handlePendingShareCode()
        }
    }

    private func handlePendingShareCode() {
        if let shareCode = router.consumePendingShareCode() {
            router.navigate(to: .guestJoin(shareCode: shareCode))
        }
    }

    private var tripList: some View {
        List {
            ForEach(viewModel.trips) { trip in
                Button {
                    router.navigate(to: .tripDetail(tripId: trip.id))
                } label: {
                    TripCard(
                        trip: trip,
                        members: viewModel.membersByTrip[trip.id] ?? [],
                        photoCount: viewModel.photoCountsByTrip[trip.id] ?? 0
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(
                    top: Spacing.xs,
                    leading: Spacing.md,
                    bottom: Spacing.xs,
                    trailing: Spacing.md
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                let trip = viewModel.trips[index]
                Task {
                    await viewModel.deleteTrip(trip)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadTrips()
        }
    }
}
