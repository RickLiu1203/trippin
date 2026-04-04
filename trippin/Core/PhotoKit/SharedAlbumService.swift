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
    let isShared: Bool
}

@MainActor
protocol SharedAlbumService: Sendable {
    func fetchAlbums() async -> [SharedAlbum]
    func fetchAlbum(id: String) async -> SharedAlbum?
    func fetchPhotos(albumIdentifier: String) async -> [PHAsset]
}

final class PhotoKitSharedAlbumService: SharedAlbumService {
    func fetchAlbums() async -> [SharedAlbum] {
        var albums: [SharedAlbum] = []

        let shared = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .albumCloudShared, options: nil
        )
        shared.enumerateObjects { collection, _, _ in
            let count = collection.estimatedAssetCount
            albums.append(SharedAlbum(
                id: collection.localIdentifier,
                title: collection.localizedTitle ?? "Untitled",
                assetCount: count == NSNotFound ? 0 : count,
                isShared: true
            ))
        }

        let regular = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .albumRegular, options: nil
        )
        regular.enumerateObjects { collection, _, _ in
            let count = collection.estimatedAssetCount
            albums.append(SharedAlbum(
                id: collection.localIdentifier,
                title: collection.localizedTitle ?? "Untitled",
                assetCount: count == NSNotFound ? 0 : count,
                isShared: false
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
        let isShared = collection.assetCollectionSubtype == .albumCloudShared
        return SharedAlbum(
            id: collection.localIdentifier,
            title: collection.localizedTitle ?? "Untitled",
            assetCount: count == NSNotFound ? 0 : count,
            isShared: isShared
        )
    }
}
