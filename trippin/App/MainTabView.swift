//
//  MainTabView.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct MainTabView: View {
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab("Trips", systemImage: "suitcase.fill", value: .trips) {
                NavigationStack(path: $router.tripsPath) {
                    TripListScreen()
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
            }

            Tab("Map", systemImage: "map.fill", value: .map) {
                NavigationStack(path: $router.mapPath) {
                    MapPlaceholderScreen()
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
            }

            Tab("Photos", systemImage: "photo.stack.fill", value: .photos) {
                NavigationStack(path: $router.photosPath) {
                    PhotosPlaceholderScreen()
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
            }

            Tab("Profile", systemImage: "person.circle.fill", value: .profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfilePlaceholderScreen()
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
            }
        }
        .tint(Color.paperPrimary)
    }

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .tripDetail(let tripId):
            TripDetailScreen(tripId: tripId)
        case .createTrip:
            PlaceholderDetailScreen(title: "Create Trip")
        case .editTrip(let tripId):
            PlaceholderDetailScreen(title: "Edit Trip", id: tripId)
        case .linkAlbum(let tripId):
            PlaceholderDetailScreen(title: "Link Album", id: tripId)
        case .dayView(let tripId, let dayIndex):
            PlaceholderDetailScreen(title: "Day \(dayIndex + 1)", id: tripId)
        case .eventDetail(let clusterId):
            PlaceholderDetailScreen(title: "Event Detail", id: clusterId)
        case .shareTrip:
            PlaceholderDetailScreen(title: "Share Trip")
        case .clusterDetail(let clusterId):
            PlaceholderDetailScreen(title: "Cluster Detail", id: clusterId)
        case .photoDetail(let photoId):
            PlaceholderDetailScreen(title: "Photo Detail", id: photoId)
        case .photoFilter(let tripId):
            PlaceholderDetailScreen(title: "Photo Filter", id: tripId)
        case .photoSearch(let tripId):
            PlaceholderDetailScreen(title: "Photo Search", id: tripId)
        case .settings:
            PlaceholderDetailScreen(title: "Settings")
        case .account:
            PlaceholderDetailScreen(title: "Account")
        case .placeReview(let tripId):
            PlaceholderDetailScreen(title: "Place Review", id: tripId)
        case .deviceClaim(let tripId):
            PlaceholderDetailScreen(title: "Device Claim", id: tripId)
        case .guestJoin(let shareCode):
            JoinTripScreen(shareCode: shareCode)
        }
    }
}
