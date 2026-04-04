//
//  SharedAlbumService.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Photos

struct SharedAlbum: Identifiable, Sendable {
    let id: String
    let title: String
    let assetCount: Int
}

@MainActor
protocol SharedAlbumService: Sendable {
    func fetchSharedAlbums() async -> [SharedAlbum]
    func fetchAlbum(id: String) async -> SharedAlbum?
    func fetchPhotos(albumIdentifier: String) async -> [PHAsset]
}

final class PhotoKitSharedAlbumService: SharedAlbumService {
    func fetchSharedAlbums() async -> [SharedAlbum] {
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumCloudShared,
            options: nil
        )
        var albums: [SharedAlbum] = []
        collections.enumerateObjects { collection, _, _ in
            let count = collection.estimatedAssetCount
            albums.append(SharedAlbum(
                id: collection.localIdentifier,
                title: collection.localizedTitle ?? "Untitled",
                assetCount: count == NSNotFound ? 0 : count
            ))
        }
        return albums
    }

    func fetchPhotos(albumIdentifier: String) async -> [PHAsset] {
        guard let collection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumIdentifier], options: nil
        ).firstObject else { return [] }

        let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    func fetchAlbum(id: String) async -> SharedAlbum? {
        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [id],
            options: nil
        )
        guard let collection = collections.firstObject else { return nil }
        let count = collection.estimatedAssetCount
        return SharedAlbum(
            id: collection.localIdentifier,
            title: collection.localizedTitle ?? "Untitled",
            assetCount: count == NSNotFound ? 0 : count
        )
    }
}
