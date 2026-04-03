//
//  AppRouter.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .trips
    var tripsPath = NavigationPath()
    var mapPath = NavigationPath()
    var photosPath = NavigationPath()
    var profilePath = NavigationPath()
    var pendingShareCode: String?

    func navigate(to route: AppRoute, tab: AppTab? = nil) {
        if let tab {
            selectedTab = tab
        }
        switch selectedTab {
        case .trips: tripsPath.append(route)
        case .map: mapPath.append(route)
        case .photos: photosPath.append(route)
        case .profile: profilePath.append(route)
        }
    }

    func popToRoot(tab: AppTab? = nil) {
        switch tab ?? selectedTab {
        case .trips: tripsPath = NavigationPath()
        case .map: mapPath = NavigationPath()
        case .photos: photosPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    func handleDeepLink(_ url: URL) {
        guard let shareCode = Self.parseShareCode(from: url) else { return }
        pendingShareCode = shareCode
        selectedTab = .trips
    }

    func consumePendingShareCode() -> String? {
        defer { pendingShareCode = nil }
        return pendingShareCode
    }

    nonisolated static func parseShareCode(from url: URL) -> String? {
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 3,
              pathComponents[1] == "trip"
        else { return nil }

        let code = pathComponents[2]
        guard !code.isEmpty else { return nil }
        return code
    }
}
