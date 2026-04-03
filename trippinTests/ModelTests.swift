//
//  ModelTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
@testable import trippin

// MARK: - JSON Helpers

private let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .secondsSince1970
    return e
}()

private let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .secondsSince1970
    return d
}()

/// Creates a Date with second precision (no subsecond fractions) for reliable round-trip testing.
private func stableDate(_ timeInterval: TimeInterval = 1_700_000_000) -> Date {
    Date(timeIntervalSince1970: timeInterval)
}

private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
    let data = try encoder.encode(value)
    return try decoder.decode(T.self, from: data)
}

// MARK: - Enum Tests

@Suite("PhotoCategory Tests")
struct PhotoCategoryTests {
    @Test("has exactly 4 cases")
    func caseCount() {
        #expect(PhotoCategory.allCases.count == 4)
    }

    @Test("contains correct categories")
    func correctCategories() {
        let cases = Set(PhotoCategory.allCases)
        #expect(cases.contains(.food))
        #expect(cases.contains(.scenery))
        #expect(cases.contains(.landmark))
        #expect(cases.contains(.activity))
    }

    @Test("raw values encode to snake_case strings")
    func rawValues() {
        #expect(PhotoCategory.food.rawValue == "food")
        #expect(PhotoCategory.scenery.rawValue == "scenery")
        #expect(PhotoCategory.landmark.rawValue == "landmark")
        #expect(PhotoCategory.activity.rawValue == "activity")
    }

    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        for category in PhotoCategory.allCases {
            let decoded = try roundTrip(category)
            #expect(decoded == category)
        }
    }
}

@Suite("MemberRole Tests")
struct MemberRoleTests {
    @Test("raw values")
    func rawValues() {
        #expect(MemberRole.owner.rawValue == "owner")
        #expect(MemberRole.member.rawValue == "member")
        #expect(MemberRole.guest.rawValue == "guest")
    }

    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let roles: [MemberRole] = [.owner, .member, .guest]
        for role in roles {
            let decoded = try roundTrip(role)
            #expect(decoded == role)
        }
    }
}

@Suite("ProcessingStatus Tests")
struct ProcessingStatusTests {
    @Test("raw values")
    func rawValues() {
        #expect(ProcessingStatus.idle.rawValue == "idle")
        #expect(ProcessingStatus.processing.rawValue == "processing")
        #expect(ProcessingStatus.complete.rawValue == "complete")
        #expect(ProcessingStatus.error.rawValue == "error")
    }
}

@Suite("PlaceSource Tests")
struct PlaceSourceTests {
    @Test("raw values")
    func rawValues() {
        #expect(PlaceSource.google.rawValue == "google")
        #expect(PlaceSource.userInput.rawValue == "user_input")
    }

    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let sources: [PlaceSource] = [.google, .userInput]
        for source in sources {
            let decoded = try roundTrip(source)
            #expect(decoded == source)
        }
    }
}

// MARK: - Model Round-Trip Tests

@Suite("Profile Tests")
struct ProfileTests {
    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let profile = Profile(
            id: UUID(),
            displayName: "Rick",
            avatarUrl: "https://example.com/avatar.png",
            createdAt: stableDate(),
            updatedAt: stableDate(1_700_001_000)
        )
        let decoded = try roundTrip(profile)
        #expect(decoded == profile)
    }

    @Test("nil avatar_url round-trip")
    func nilAvatarUrl() throws {
        let profile = Profile(
            id: UUID(),
            displayName: "Guest",
            avatarUrl: nil,
            createdAt: stableDate(),
            updatedAt: stableDate()
        )
        let decoded = try roundTrip(profile)
        #expect(decoded.avatarUrl == nil)
        #expect(decoded.displayName == "Guest")
    }

    @Test("encodes to snake_case keys")
    func snakeCaseKeys() throws {
        let profile = Profile(
            id: UUID(),
            displayName: "Rick",
            avatarUrl: "test",
            createdAt: stableDate(),
            updatedAt: stableDate()
        )
        let data = try encoder.encode(profile)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"display_name\""))
        #expect(json.contains("\"avatar_url\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))
    }
}

@Suite("Trip Tests")
struct TripTests {
    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let trip = Trip(
            id: UUID(),
            ownerId: UUID(),
            name: "Japan 2026",
            shareCode: "abc123def456",
            albumIdentifier: nil,
            createdAt: stableDate(),
            updatedAt: stableDate(1_700_001_000)
        )
        let decoded = try roundTrip(trip)
        #expect(decoded == trip)
    }

    @Test("with album identifier")
    func withAlbumIdentifier() throws {
        let trip = Trip(
            id: UUID(),
            ownerId: UUID(),
            name: "Paris",
            shareCode: "xyz789",
            albumIdentifier: "shared-album-123",
            createdAt: stableDate(),
            updatedAt: stableDate()
        )
        let decoded = try roundTrip(trip)
        #expect(decoded.albumIdentifier == "shared-album-123")
    }

    @Test("encodes to snake_case keys")
    func snakeCaseKeys() throws {
        let trip = Trip(
            id: UUID(),
            ownerId: UUID(),
            name: "Test",
            shareCode: "abc",
            albumIdentifier: "test-album",
            createdAt: stableDate(),
            updatedAt: stableDate()
        )
        let data = try encoder.encode(trip)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"owner_id\""))
        #expect(json.contains("\"share_code\""))
        #expect(json.contains("\"album_identifier\""))
    }
}

@Suite("TripMember Tests")
struct TripMemberTests {
    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let member = TripMember(
            id: UUID(),
            tripId: UUID(),
            userId: UUID(),
            displayName: "Alice",
            emoji: "🌸",
            color: "#FF69B4",
            role: .member,
            cameraIdentifier: "iPhone15Pro-ABC123",
            createdAt: stableDate()
        )
        let decoded = try roundTrip(member)
        #expect(decoded == member)
    }

    @Test("nil camera identifier")
    func nilCameraIdentifier() throws {
        let member = TripMember(
            id: UUID(),
            tripId: UUID(),
            userId: UUID(),
            displayName: "Bob",
            emoji: "🎸",
            color: "#4287f5",
            role: .guest,
            cameraIdentifier: nil,
            createdAt: stableDate()
        )
        let decoded = try roundTrip(member)
        #expect(decoded.cameraIdentifier == nil)
        #expect(decoded.role == .guest)
    }
}

@Suite("PhotoMetadata Tests")
struct PhotoMetadataTests {
    @Test("JSON round-trip with all fields")
    func fullRoundTrip() throws {
        let photo = PhotoMetadata(
            id: UUID(),
            tripId: UUID(),
            memberId: UUID(),
            localAssetId: "PHAsset/12345",
            latitude: 35.6762,
            longitude: 139.6503,
            takenAt: stableDate(),
            cameraMake: "Apple",
            cameraModel: "iPhone 15 Pro",
            cameraSerial: "ABC123",
            category: .landmark,
            confidence: 0.95,
            dayIndex: 0
        )
        let decoded = try roundTrip(photo)
        #expect(decoded == photo)
    }

    @Test("nil optionals round-trip")
    func nilOptionals() throws {
        let photo = PhotoMetadata(
            id: UUID(),
            tripId: UUID(),
            memberId: nil,
            localAssetId: "PHAsset/99999",
            latitude: nil,
            longitude: nil,
            takenAt: stableDate(),
            cameraMake: nil,
            cameraModel: nil,
            cameraSerial: nil,
            category: nil,
            confidence: nil,
            dayIndex: nil
        )
        let decoded = try roundTrip(photo)
        #expect(decoded.memberId == nil)
        #expect(decoded.latitude == nil)
        #expect(decoded.longitude == nil)
        #expect(decoded.cameraMake == nil)
        #expect(decoded.category == nil)
        #expect(decoded.confidence == nil)
        #expect(decoded.dayIndex == nil)
    }

    @Test("encodes to snake_case keys")
    func snakeCaseKeys() throws {
        let photo = PhotoMetadata(
            id: UUID(),
            tripId: UUID(),
            memberId: UUID(),
            localAssetId: "test",
            latitude: 1.0,
            longitude: 2.0,
            takenAt: stableDate(),
            cameraMake: "Apple",
            cameraModel: "iPhone",
            cameraSerial: "serial",
            category: .food,
            confidence: 0.9,
            dayIndex: 1
        )
        let data = try encoder.encode(photo)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"trip_id\""))
        #expect(json.contains("\"local_asset_id\""))
        #expect(json.contains("\"taken_at\""))
        #expect(json.contains("\"camera_make\""))
        #expect(json.contains("\"day_index\""))
    }
}

@Suite("PhotoCluster Tests")
struct PhotoClusterModelTests {
    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let cluster = PhotoCluster(
            id: UUID(),
            tripId: UUID(),
            centroidLat: 48.8566,
            centroidLon: 2.3522,
            startTime: stableDate(),
            endTime: stableDate(1_700_003_600),
            dayIndex: 1,
            clusterOrder: 0,
            placeId: UUID(),
            photoCount: 12
        )
        let decoded = try roundTrip(cluster)
        #expect(decoded == cluster)
    }

    @Test("nil place_id")
    func nilPlaceId() throws {
        let cluster = PhotoCluster(
            id: UUID(),
            tripId: UUID(),
            centroidLat: 0,
            centroidLon: 0,
            startTime: stableDate(),
            endTime: stableDate(),
            dayIndex: 0,
            clusterOrder: 0,
            placeId: nil,
            photoCount: 3
        )
        let decoded = try roundTrip(cluster)
        #expect(decoded.placeId == nil)
    }
}

@Suite("ClusterPhoto Tests")
struct ClusterPhotoTests {
    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let cp = ClusterPhoto(
            id: UUID(),
            clusterId: UUID(),
            photoMetadataId: UUID()
        )
        let decoded = try roundTrip(cp)
        #expect(decoded == cp)
    }
}

@Suite("Place Tests")
struct PlaceTests {
    @Test("JSON round-trip with Google source")
    func googlePlace() throws {
        let place = Place(
            id: UUID(),
            googlePlaceId: "ChIJD7fiBh9u5kcRYJSMaMOCCwQ",
            name: "Eiffel Tower",
            address: "Champ de Mars, Paris",
            latitude: 48.8584,
            longitude: 2.2945,
            category: "landmark",
            source: .google
        )
        let decoded = try roundTrip(place)
        #expect(decoded == place)
    }

    @Test("JSON round-trip with user input source")
    func userInputPlace() throws {
        let place = Place(
            id: UUID(),
            googlePlaceId: nil,
            name: "Secret Ramen Spot",
            address: nil,
            latitude: 35.6762,
            longitude: 139.6503,
            category: "food",
            source: .userInput
        )
        let decoded = try roundTrip(place)
        #expect(decoded.googlePlaceId == nil)
        #expect(decoded.source == .userInput)
    }
}

@Suite("DeviceMapping Tests")
struct DeviceMappingTests {
    @Test("JSON round-trip")
    func jsonRoundTrip() throws {
        let mapping = DeviceMapping(
            id: UUID(),
            tripId: UUID(),
            cameraIdentifier: "Apple-iPhone15Pro-ABC123",
            memberId: UUID()
        )
        let decoded = try roundTrip(mapping)
        #expect(decoded == mapping)
    }
}

// MARK: - AppRoute Tests

@Suite("AppRoute Tests")
struct AppRouteTests {
    @Test("trip routes carry correct IDs")
    func tripRoutes() {
        let tripId = UUID()
        let route = AppRoute.tripDetail(tripId: tripId)
        if case .tripDetail(let id) = route {
            #expect(id == tripId)
        } else {
            Issue.record("Expected tripDetail route")
        }
    }

    @Test("day view carries trip ID and day index")
    func dayViewRoute() {
        let tripId = UUID()
        let route = AppRoute.dayView(tripId: tripId, dayIndex: 3)
        if case .dayView(let id, let day) = route {
            #expect(id == tripId)
            #expect(day == 3)
        } else {
            Issue.record("Expected dayView route")
        }
    }

    @Test("guest join carries share code")
    func guestJoinRoute() {
        let route = AppRoute.guestJoin(shareCode: "abc123def456")
        if case .guestJoin(let code) = route {
            #expect(code == "abc123def456")
        } else {
            Issue.record("Expected guestJoin route")
        }
    }

    @Test("routes are hashable for NavigationPath")
    func hashable() {
        let route1 = AppRoute.tripDetail(tripId: UUID())
        let route2 = AppRoute.settings
        let set: Set<AppRoute> = [route1, route2]
        #expect(set.count == 2)
    }
}

@Suite("AppTab Tests")
struct AppTabTests {
    @Test("tab raw values")
    func tabValues() {
        #expect(AppTab.trips.rawValue == 0)
        #expect(AppTab.map.rawValue == 1)
        #expect(AppTab.photos.rawValue == 2)
        #expect(AppTab.profile.rawValue == 3)
    }
}
