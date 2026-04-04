//
//  PhotoClassifierTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import Foundation
import Vision
@testable import trippin

private func makeObservation(identifier: String, confidence: Float) -> VNClassificationObservation {
    let observation = VNClassificationObservation()
    observation.setValue(identifier, forKey: "identifier")
    observation.setValue(NSNumber(value: confidence), forKey: "confidence")
    return observation
}

@Suite("CategoryMapper Label Tests")
struct CategoryMapperLabelTests {
    @Test("food labels map to food category")
    func foodLabels() {
        #expect(CategoryMapper.categoryFor(label: "food") == .food)
        #expect(CategoryMapper.categoryFor(label: "pizza") == .food)
        #expect(CategoryMapper.categoryFor(label: "coffee") == .food)
        #expect(CategoryMapper.categoryFor(label: "sushi") == .food)
        #expect(CategoryMapper.categoryFor(label: "restaurant") == .food)
        #expect(CategoryMapper.categoryFor(label: "ramen") == .food)
    }

    @Test("scenery labels map to scenery category")
    func sceneryLabels() {
        #expect(CategoryMapper.categoryFor(label: "landscape") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "mountain") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "beach") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "sunset") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "ocean") == .scenery)
    }

    @Test("landmark labels map to landmark category")
    func landmarkLabels() {
        #expect(CategoryMapper.categoryFor(label: "temple") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "castle") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "monument") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "museum") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "cathedral") == .landmark)
    }

    @Test("people labels require face-forward indicators")
    func peopleLabels() {
        #expect(CategoryMapper.categoryFor(label: "portrait") == .people)
        #expect(CategoryMapper.categoryFor(label: "selfie") == .people)
        #expect(CategoryMapper.categoryFor(label: "face") == .people)
        #expect(CategoryMapper.categoryFor(label: "person") == nil)
        #expect(CategoryMapper.categoryFor(label: "people") == nil)
        #expect(CategoryMapper.categoryFor(label: "crowd") == nil)
    }

    @Test("broad labels that were removed return nil")
    func removedBroadLabels() {
        #expect(CategoryMapper.categoryFor(label: "outdoor") == nil)
        #expect(CategoryMapper.categoryFor(label: "nature") == nil)
        #expect(CategoryMapper.categoryFor(label: "building") == nil)
        #expect(CategoryMapper.categoryFor(label: "architecture") == nil)
        #expect(CategoryMapper.categoryFor(label: "sky") == nil)
    }

    @Test("unrelated labels return nil")
    func unknownLabels() {
        #expect(CategoryMapper.categoryFor(label: "car") == nil)
        #expect(CategoryMapper.categoryFor(label: "suitcase") == nil)
        #expect(CategoryMapper.categoryFor(label: "phone") == nil)
        #expect(CategoryMapper.categoryFor(label: "text") == nil)
    }

    @Test("word boundary matching prevents substring false positives")
    func wordBoundary() {
        #expect(CategoryMapper.categoryFor(label: "suitcase") == nil)
        #expect(CategoryMapper.categoryFor(label: "bookcase") == nil)
        #expect(CategoryMapper.categoryFor(label: "snowboard") == nil)
    }

    @Test("compound labels with separators match individual words")
    func compoundLabels() {
        #expect(CategoryMapper.categoryFor(label: "mountain_snow") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "food_pizza") == .food)
        #expect(CategoryMapper.categoryFor(label: "temple_gate") == .landmark)
    }

    @Test("labels are case insensitive")
    func caseInsensitive() {
        #expect(CategoryMapper.categoryFor(label: "FOOD") == .food)
        #expect(CategoryMapper.categoryFor(label: "Mountain") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "TEMPLE") == .landmark)
    }
}

@Suite("CategoryMapper Observation Mapping Tests")
struct CategoryMapperObservationTests {
    @Test("food always wins when present")
    func foodAlwaysWins() {
        let observations = [
            makeObservation(identifier: "person", confidence: 0.9),
            makeObservation(identifier: "food", confidence: 0.15),
            makeObservation(identifier: "landscape", confidence: 0.3),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .food)
    }

    @Test("portrait label maps to people")
    func portraitMapsToPeople() {
        let observations = [
            makeObservation(identifier: "portrait", confidence: 0.9),
            makeObservation(identifier: "text", confidence: 0.1),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .people)
    }

    @Test("face with strong scenery prefers scenery")
    func faceWithSceneryPrefersScenery() {
        let observations = [
            makeObservation(identifier: "face", confidence: 0.6),
            makeObservation(identifier: "landscape", confidence: 0.4),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .scenery)
    }

    @Test("generic person label does not trigger people category")
    func genericPersonIsMisc() {
        let observations = [
            makeObservation(identifier: "person", confidence: 0.9),
            makeObservation(identifier: "street", confidence: 0.3),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .miscellaneous)
    }

    @Test("low confidence scenery falls to miscellaneous")
    func lowConfidenceSceneryIsMisc() {
        let observations = [
            makeObservation(identifier: "landscape", confidence: 0.15),
            makeObservation(identifier: "vehicle", confidence: 0.8),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .miscellaneous)
    }

    @Test("unrecognized labels default to miscellaneous")
    func unknownDefaultsToMisc() {
        let observations = [
            makeObservation(identifier: "vehicle", confidence: 0.8),
            makeObservation(identifier: "text", confidence: 0.5),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .miscellaneous)
    }

    @Test("empty observations default to miscellaneous")
    func emptyObservations() {
        let result = CategoryMapper.map(observations: [])
        #expect(result.category == .miscellaneous)
    }

    @Test("all six categories exist")
    func allCategoriesExist() {
        #expect(PhotoCategory.allCases.count == 6)
        #expect(PhotoCategory.allCases.contains(.food))
        #expect(PhotoCategory.allCases.contains(.scenery))
        #expect(PhotoCategory.allCases.contains(.landmark))
        #expect(PhotoCategory.allCases.contains(.activity))
        #expect(PhotoCategory.allCases.contains(.people))
        #expect(PhotoCategory.allCases.contains(.miscellaneous))
    }

    @Test("activity labels with sufficient confidence map to activity")
    func activityLabels() {
        let observations = [
            makeObservation(identifier: "hiking", confidence: 0.6),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .activity)
    }
}
