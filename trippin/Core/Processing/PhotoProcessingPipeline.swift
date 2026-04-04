//
//  PhotoProcessingPipeline.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Photos

enum ProcessingState: Sendable, Equatable {
    case idle
    case processing(completed: Int, total: Int)
    case complete(newCount: Int)
    case error(String)
}

struct ProcessingResult: Sendable {
    let processedCount: Int
    let withLocation: Int
    let withoutLocation: Int
    let totalInAlbum: Int
    let skippedAlreadyProcessed: Int
    let uniqueDevicesWithoutLocation: Int
    let unclaimedDevices: [UnclaimedDevice]
}

struct UnclaimedDevice: Sendable, Equatable {
    let cameraIdentifier: String
    let cameraModel: String?
}

actor PhotoProcessingPipeline {
    let albumService: SharedAlbumService
    let metadataService: PhotoMetadataService
    let exifExtractor: EXIFExtractorService
    let classifier: PhotoClassifierService
    let deviceMatcher: DeviceMatcher

    private(set) var state: ProcessingState = .idle

    init(
        albumService: SharedAlbumService,
        metadataService: PhotoMetadataService,
        exifExtractor: EXIFExtractorService,
        classifier: PhotoClassifierService,
        deviceMatcher: DeviceMatcher
    ) {
        self.albumService = albumService
        self.metadataService = metadataService
        self.exifExtractor = exifExtractor
        self.classifier = classifier
        self.deviceMatcher = deviceMatcher
    }

    func process(tripId: UUID, albumIdentifier: String) async -> ProcessingResult {
        state = .processing(completed: 0, total: 0)

        let assets = await albumService.fetchPhotos(albumIdentifier: albumIdentifier)
        let totalInAlbum = assets.count
        if assets.isEmpty {
            state = .complete(newCount: 0)
            return ProcessingResult(processedCount: 0, withLocation: 0, withoutLocation: 0, totalInAlbum: 0, skippedAlreadyProcessed: 0, uniqueDevicesWithoutLocation: 0, unclaimedDevices: [])
        }

        let existingIds: Set<String>
        do {
            existingIds = try await metadataService.fetchExistingAssetIds(tripId: tripId)
        } catch {
            state = .error(error.localizedDescription)
            return ProcessingResult(processedCount: 0, withLocation: 0, withoutLocation: 0, totalInAlbum: totalInAlbum, skippedAlreadyProcessed: 0, uniqueDevicesWithoutLocation: 0, unclaimedDevices: [])
        }

        let skippedCount = existingIds.count
        let newAssets = assets.filter { !existingIds.contains($0.localIdentifier) }
        if newAssets.isEmpty {
            state = .complete(newCount: 0)
            return ProcessingResult(processedCount: 0, withLocation: 0, withoutLocation: 0, totalInAlbum: totalInAlbum, skippedAlreadyProcessed: skippedCount, uniqueDevicesWithoutLocation: 0, unclaimedDevices: [])
        }

        let total = newAssets.count
        state = .processing(completed: 0, total: total)

        let extractedBatch = await exifExtractor.extractBatch(from: newAssets, maxConcurrent: 5)
        let classifications = await classifier.classifyBatch(assets: newAssets, maxConcurrent: 5)

        var insertParams: [InsertPhotoMetadataParams] = []
        var unclaimedDevices: [UnclaimedDevice] = []
        var seenUnclaimed: Set<String> = []
        var devicesWithoutLocation: Set<String> = []

        for extracted in extractedBatch {
            let classification = classifications[extracted.localAssetId]

            var memberId: UUID?
            let matchResult = try? await deviceMatcher.matchDevice(
                tripId: tripId,
                make: extracted.cameraMake,
                model: extracted.cameraModel,
                serial: extracted.cameraSerial
            )
            if case .matched(let id) = matchResult {
                memberId = id
            } else if case .needsClaim(let identifier, let model) = matchResult {
                if !seenUnclaimed.contains(identifier) {
                    seenUnclaimed.insert(identifier)
                    unclaimedDevices.append(UnclaimedDevice(
                        cameraIdentifier: identifier,
                        cameraModel: model
                    ))
                }
            }

            if extracted.latitude == nil || extracted.longitude == nil {
                let deviceKey = [extracted.cameraMake ?? "", extracted.cameraModel ?? ""].joined(separator: "|")
                if !deviceKey.isEmpty && deviceKey != "|" {
                    devicesWithoutLocation.insert(deviceKey)
                }
            }

            insertParams.append(InsertPhotoMetadataParams(
                tripId: tripId,
                memberId: memberId,
                localAssetId: extracted.localAssetId,
                latitude: extracted.latitude,
                longitude: extracted.longitude,
                takenAt: extracted.takenAt,
                cameraMake: extracted.cameraMake,
                cameraModel: extracted.cameraModel,
                cameraSerial: extracted.cameraSerial,
                category: classification?.category.rawValue,
                confidence: classification?.confidence
            ))

            state = .processing(completed: insertParams.count, total: total)
        }

        let withLoc = insertParams.filter { $0.latitude != nil && $0.longitude != nil }.count
        let withoutLoc = insertParams.count - withLoc

        do {
            try await metadataService.insertBatch(insertParams)
        } catch {
            state = .error(error.localizedDescription)
            return ProcessingResult(processedCount: 0, withLocation: withLoc, withoutLocation: withoutLoc, totalInAlbum: totalInAlbum, skippedAlreadyProcessed: skippedCount, uniqueDevicesWithoutLocation: devicesWithoutLocation.count, unclaimedDevices: unclaimedDevices)
        }

        state = .complete(newCount: insertParams.count)
        return ProcessingResult(processedCount: insertParams.count, withLocation: withLoc, withoutLocation: withoutLoc, totalInAlbum: totalInAlbum, skippedAlreadyProcessed: skippedCount, uniqueDevicesWithoutLocation: devicesWithoutLocation.count, unclaimedDevices: unclaimedDevices)
    }

    static func diffAssetIds(album: [String], existing: Set<String>) -> [String] {
        album.filter { !existing.contains($0) }
    }
}
