//
//  LinkAlbumViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class LinkAlbumViewModel {
    private(set) var albums: [SharedAlbum] = []
    private(set) var isLoading = true

    let albumService: SharedAlbumService

    init(albumService: SharedAlbumService? = nil) {
        self.albumService = albumService ?? PhotoKitSharedAlbumService()
    }

    func loadAlbums() async {
        albums = await albumService.fetchSharedAlbums()
        isLoading = false
    }
}
