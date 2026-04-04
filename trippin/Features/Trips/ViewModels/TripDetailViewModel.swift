//
//  TripDetailViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Observation

@MainActor
@Observable
final class TripDetailViewModel {
    private(set) var trip: Trip?
    private(set) var members: [TripMember] = []
    private(set) var linkedAlbum: SharedAlbum?
    private(set) var timelineDays: [TimelineDay] = []
    private(set) var photoMetadata: [PhotoMetadata] = []
    private(set) var metadataById: [UUID: PhotoMetadata] = [:]
    private(set) var isLoading = false
    private(set) var processingState: ProcessingState = .idle
    private(set) var lastProcessingResult: ProcessingResult?
    private(set) var syncedPhotoCount: Int = 0
    private(set) var waitingDeviceCount: Int = 0
    private(set) var waitingPhotoCount: Int = 0
    var error: String?
    var showEditSheet = false
    var showLinkAlbumSheet = false
    var showShareSheet = false
    var userId: UUID?

    let tripId: UUID
    let tripService: TripService
    let memberService: TripMemberService
    let albumService: SharedAlbumService
    let clusterService: ClusterService
    let photoMetadataService: PhotoMetadataService

    private var pipeline: PhotoProcessingPipeline?

    init(
        tripId: UUID,
        tripService: TripService? = nil,
        memberService: TripMemberService? = nil,
        albumService: SharedAlbumService? = nil,
        clusterService: ClusterService? = nil,
        photoMetadataService: PhotoMetadataService? = nil
    ) {
        self.tripId = tripId
        self.tripService = tripService ?? SupabaseTripService()
        self.memberService = memberService ?? SupabaseTripMemberService()
        self.albumService = albumService ?? PhotoKitSharedAlbumService()
        self.clusterService = clusterService ?? SupabaseClusterService()
        self.photoMetadataService = photoMetadataService ?? SupabasePhotoMetadataService()
    }

    var isOwner: Bool {
        trip?.ownerId == userId
    }

    func loadTrip() async {
        isLoading = true
        error = nil
        do {
            trip = try await tripService.fetchTrip(id: tripId)
            members = try await memberService.fetchMembers(tripId: tripId)
            if let albumId = trip?.albumIdentifier {
                linkedAlbum = await albumService.fetchAlbum(id: albumId)
            }
            await loadTimeline()
            isLoading = false
            if trip?.albumIdentifier != nil {
                Task { await processPhotos() }
            }
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func linkAlbum(_ albumIdentifier: String) async {
        do {
            trip = try await tripService.updateTripAlbum(id: tripId, albumIdentifier: albumIdentifier)
            linkedAlbum = await albumService.fetchAlbum(id: albumIdentifier)
            await processPhotos()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func processPhotos() async {
        guard let albumId = trip?.albumIdentifier else { return }

        let deviceMappingService = SupabaseDeviceMappingService()
        let pipe = PhotoProcessingPipeline(
            albumService: albumService,
            metadataService: photoMetadataService,
            exifExtractor: PhotoKitEXIFExtractor(),
            classifier: VisionPhotoClassifier(),
            deviceMatcher: DeviceMatcher(mappingService: deviceMappingService)
        )
        pipeline = pipe

        processingState = .processing(completed: 0, total: 0)
        let result = await pipe.process(tripId: tripId, albumIdentifier: albumId)
        processingState = await pipe.state
        lastProcessingResult = result

        if result.processedCount > 0 {
            let clusterer = DBSCANClusterer()
            let allMetadata = try? await photoMetadataService.fetchAll(tripId: tripId)
            let points = (allMetadata ?? []).compactMap { meta -> PhotoPoint? in
                guard let lat = meta.latitude, let lon = meta.longitude else { return nil }
                return PhotoPoint(id: meta.id, latitude: lat, longitude: lon, takenAt: meta.takenAt)
            }

            let clusterResults = clusterer.clusterWithDaySplit(points)
            let metadataMap = Dictionary(uniqueKeysWithValues: (allMetadata ?? []).map { ($0.id, $0) })
            let days = TimelineGenerator.generate(clusters: clusterResults, metadata: metadataMap)

            try? await clusterService.replaceClusters(tripId: tripId, days: days)
            await loadTimeline()
        }
    }

    func loadTimeline() async {
        do {
            let clusters = try await clusterService.fetchClusters(tripId: tripId)
            let clusterPhotos = try await clusterService.fetchClusterPhotos(tripId: tripId)
            photoMetadata = try await photoMetadataService.fetchAll(tripId: tripId)
            metadataById = Dictionary(uniqueKeysWithValues: photoMetadata.map { ($0.id, $0) })
            timelineDays = TimelineGenerator.generateFromDB(
                clusters: clusters,
                clusterPhotos: clusterPhotos,
                metadata: photoMetadata
            )
            computeSyncStats()
        } catch {
            timelineDays = []
        }
    }

    private func computeSyncStats() {
        let withLocation = photoMetadata.filter { $0.latitude != nil && $0.longitude != nil }
        let withoutLocation = photoMetadata.filter { $0.latitude == nil || $0.longitude == nil }
        syncedPhotoCount = withLocation.count

        var devices: Set<String> = []
        for meta in withoutLocation {
            let key = [meta.cameraMake ?? "", meta.cameraModel ?? ""].joined(separator: "|")
            if !key.isEmpty && key != "|" {
                devices.insert(key)
            }
        }
        waitingDeviceCount = devices.count
        waitingPhotoCount = withoutLocation.count
    }

    func eventById(_ eventId: UUID) -> TimelineEvent? {
        timelineDays.flatMap(\.events).first { $0.id == eventId }
    }

    func photosForEvent(_ event: TimelineEvent) -> [PhotoMetadata] {
        event.photoMetadataIds.compactMap { metadataById[$0] }
    }

    func removeMember(_ member: TripMember) async {
        do {
            try await memberService.removeMember(id: member.id)
            members.removeAll { $0.id == member.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
