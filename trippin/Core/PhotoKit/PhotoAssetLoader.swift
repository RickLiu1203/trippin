//
//  PhotoAssetLoader.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Photos
import UIKit

enum PhotoAssetLoader {
    static func loadThumbnail(
        localIdentifier: String,
        size: CGSize = CGSize(width: 80, height: 80)
    ) async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        return await loadImage(for: asset, size: size)
    }

    static func loadImage(
        for asset: PHAsset,
        size: CGSize
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = true
            options.resizeMode = .fast

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
