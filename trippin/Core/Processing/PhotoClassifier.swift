//
//  PhotoClassifier.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Photos
import Vision

enum ClassificationError: Error, LocalizedError {
    case noImage
    case classificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .noImage: "Failed to load image for classification"
        case .classificationFailed(let msg): "Classification failed: \(msg)"
        }
    }
}

protocol PhotoClassifierService: Sendable {
    func classify(asset: PHAsset) async throws -> ClassificationResult
    func classifyBatch(assets: [PHAsset], maxConcurrent: Int) async -> [String: ClassificationResult]
}

final class VisionPhotoClassifier: PhotoClassifierService, @unchecked Sendable {
    private let thumbnailSize = CGSize(width: 299, height: 299)

    func classify(asset: PHAsset) async throws -> ClassificationResult {
        let image = try await requestThumbnail(for: asset)
        let observations = try performClassification(on: image)
        return CategoryMapper.map(observations: observations)
    }

    func classifyBatch(assets: [PHAsset], maxConcurrent: Int = 5) async -> [String: ClassificationResult] {
        await withTaskGroup(of: (String, ClassificationResult)?.self) { group in
            var results: [String: ClassificationResult] = [:]
            var iterator = assets.makeIterator()

            for _ in 0..<min(maxConcurrent, assets.count) {
                if let asset = iterator.next() {
                    group.addTask {
                        guard let result = try? await self.classify(asset: asset) else { return nil }
                        return (asset.localIdentifier, result)
                    }
                }
            }

            for await result in group {
                if let (id, classification) = result {
                    results[id] = classification
                }
                if let asset = iterator.next() {
                    group.addTask {
                        guard let result = try? await self.classify(asset: asset) else { return nil }
                        return (asset.localIdentifier, result)
                    }
                }
            }

            return results
        }
    }

    private func requestThumbnail(for asset: PHAsset) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let cgImage = image?.cgImage {
                    continuation.resume(returning: cgImage)
                } else {
                    continuation.resume(throwing: ClassificationError.noImage)
                }
            }
        }
    }

    private func performClassification(on image: CGImage) throws -> [VNClassificationObservation] {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])
        return request.results ?? []
    }
}
