//
//  PhotoProcessingPipelineTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
import Photos
@testable import trippin

@MainActor
final class MockPhotoMetadataService: PhotoMetadataService {
    var existingAssetIds: Set<String> = []
    var insertedMetadata: [InsertPhotoMetadataParams] = []
    var shouldFail = false

    func fetchExistingAssetIds(tripId: UUID) async throws -> Set<String> {
        if shouldFail { throw TripServiceError.notAuthenticated }
        return existingAssetIds
    }

    func insertBatch(_ metadata: [InsertPhotoMetadataParams]) async throws {
        if shouldFail { throw TripServiceError.notAuthenticated }
        insertedMetadata.append(contentsOf: metadata)
    }
}

@MainActor
final class PipelineMockAlbumService: SharedAlbumService {
    var photoAssets: [PHAsset] = []

    func fetchSharedAlbums() async -> [SharedAlbum] { [] }
    func fetchAlbum(id: String) async -> SharedAlbum? { nil }
    func fetchPhotos(albumIdentifier: String) async -> [PHAsset] { photoAssets }
}

final class MockEXIFExtractor: EXIFExtractorService, @unchecked Sendable {
    var results: [ExtractedPhotoData] = []

    func extractMetadata(from asset: PHAsset) async throws -> ExtractedPhotoData {
        results.first { $0.localAssetId == asset.localIdentifier }
            ?? ExtractedPhotoData(
                localAssetId: asset.localIdentifier,
                latitude: nil, longitude: nil,
                takenAt: Date(),
                cameraMake: nil, cameraModel: nil, cameraSerial: nil
            )
    }

    func extractBatch(from assets: [PHAsset], maxConcurrent: Int) async -> [ExtractedPhotoData] {
        results
    }
}

final class MockPhotoClassifier: PhotoClassifierService, @unchecked Sendable {
    var results: [String: ClassificationResult] = [:]

    func classify(asset: PHAsset) async throws -> ClassificationResult {
        results[asset.localIdentifier] ?? ClassificationResult(category: .activity, confidence: 0.5)
    }

    func classifyBatch(assets: [PHAsset], maxConcurrent: Int) async -> [String: ClassificationResult] {
        results
    }
}

@Suite("Photo Processing Diff Tests")
struct PhotoProcessingDiffTests {
    @Test("identifies new photos correctly")
    func diffFindsNew() {
        let album = ["a", "b", "c", "d"]
        let existing: Set<String> = ["a", "c"]
        let newIds = PhotoProcessingPipeline.diffAssetIds(album: album, existing: existing)
        #expect(newIds == ["b", "d"])
    }

    @Test("all photos are new when none exist")
    func diffAllNew() {
        let album = ["x", "y", "z"]
        let existing: Set<String> = []
        let newIds = PhotoProcessingPipeline.diffAssetIds(album: album, existing: existing)
        #expect(newIds == ["x", "y", "z"])
    }

    @Test("no new photos when all already processed")
    func diffNoneNew() {
        let album = ["a", "b"]
        let existing: Set<String> = ["a", "b"]
        let newIds = PhotoProcessingPipeline.diffAssetIds(album: album, existing: existing)
        #expect(newIds.isEmpty)
    }

    @Test("empty album produces no new photos")
    func diffEmptyAlbum() {
        let newIds = PhotoProcessingPipeline.diffAssetIds(album: [], existing: ["a"])
        #expect(newIds.isEmpty)
    }
}

@Suite("Photo Processing Pipeline State Tests")
struct PhotoProcessingPipelineStateTests {
    private func makePipeline() async -> (PhotoProcessingPipeline, MockPhotoMetadataService) {
        await MainActor.run {
            let albumService = PipelineMockAlbumService()
            let metadataService = MockPhotoMetadataService()
            let exifExtractor = MockEXIFExtractor()
            let classifier = MockPhotoClassifier()
            let deviceMappingService = MockDeviceMappingService()

            let pipeline = PhotoProcessingPipeline(
                albumService: albumService,
                metadataService: metadataService,
                exifExtractor: exifExtractor,
                classifier: classifier,
                deviceMatcher: DeviceMatcher(mappingService: deviceMappingService)
            )
            return (pipeline, metadataService)
        }
    }

    @Test("empty album transitions idle to complete with zero")
    func emptyAlbum() async {
        let (pipeline, _) = await makePipeline()
        let result = await pipeline.process(tripId: UUID(), albumIdentifier: "album-1")

        #expect(result.processedCount == 0)
        let state = await pipeline.state
        #expect(state == .complete(newCount: 0))
    }

    @Test("already-processed photos are skipped via empty album")
    func skipsProcessed() async {
        let (pipeline, metadataService) = await makePipeline()
        await MainActor.run {
            metadataService.existingAssetIds = ["asset-1", "asset-2"]
        }

        let result = await pipeline.process(tripId: UUID(), albumIdentifier: "album-1")

        #expect(result.processedCount == 0)
        let inserted = await MainActor.run { metadataService.insertedMetadata }
        #expect(inserted.isEmpty)
    }

    @Test("result includes zero unclaimed devices for empty album")
    func noUnclaimedForEmpty() async {
        let (pipeline, _) = await makePipeline()
        let result = await pipeline.process(tripId: UUID(), albumIdentifier: "album-1")

        #expect(result.unclaimedDevices.isEmpty)
    }
}
