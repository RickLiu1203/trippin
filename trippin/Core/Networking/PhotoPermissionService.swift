//
//  PhotoPermissionService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Photos
import Foundation

enum PhotoPermissionStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case limited
}

@MainActor
@Observable
final class PhotoPermissionService {
    private(set) var status: PhotoPermissionStatus = .notDetermined

    init() {
        updateStatus()
    }

    func updateStatus() {
        let phStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        status = mapStatus(phStatus)
    }

    func requestAccess() async {
        let phStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        status = mapStatus(phStatus)
    }

    private func mapStatus(_ phStatus: PHAuthorizationStatus) -> PhotoPermissionStatus {
        switch phStatus {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied, .restricted: .denied
        case .limited: .limited
        @unknown default: .denied
        }
    }
}
