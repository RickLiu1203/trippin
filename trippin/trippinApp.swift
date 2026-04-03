//
//  trippinApp.swift
//  trippin
//
//  Created by bree on 2026-04-03.
//

import SwiftUI

@main
struct trippinApp: App {
    @State private var authViewModel = AuthViewModel()
    @State private var permissionService = PhotoPermissionService()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environment(authViewModel)
                .environment(permissionService)
                .environment(router)
                .onAppear {
                    authViewModel.startObservingAuthState()
                }
                .onOpenURL { url in
                    router.handleDeepLink(url)
                }
        }
    }
}
