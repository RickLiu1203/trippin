//
//  JoinTripScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct JoinTripScreen: View {
    @State private var viewModel: JoinTripViewModel
    @Environment(AppRouter.self) private var router

    init(shareCode: String) {
        _viewModel = State(initialValue: JoinTripViewModel(shareCode: shareCode))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let guestVM = viewModel.guestJoinViewModel {
                GuestJoinScreen(viewModel: guestVM) { name, emoji, color in
                    Task {
                        if let tripId = await viewModel.joinTrip(
                            displayName: name,
                            emoji: emoji,
                            color: color
                        ) {
                            router.popToRoot(tab: .trips)
                            router.navigate(to: .tripDetail(tripId: tripId))
                        }
                    }
                }
                .overlay {
                    if viewModel.isJoining {
                        Color.paperSurface.opacity(0.6)
                        ProgressView()
                    }
                }
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn't load trip",
                    message: viewModel.error ?? "Trip not found or invalid link",
                    actionTitle: "Go Back"
                ) {
                    router.popToRoot(tab: .trips)
                }
            }
        }
        .background(Color.paperSurface)
        .navigationTitle("Join Trip")
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
            await viewModel.loadTripInfo()
        }
    }
}
