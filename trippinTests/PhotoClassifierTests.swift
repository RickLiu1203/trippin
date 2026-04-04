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
        #expect(CategoryMapper.categoryFor(label: "dessert") == .food)
    }

    @Test("scenery labels map to scenery category")
    func sceneryLabels() {
        #expect(CategoryMapper.categoryFor(label: "landscape") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "mountain") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "beach") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "sunset") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "ocean") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "nature") == .scenery)
    }

    @Test("landmark labels map to landmark category")
    func landmarkLabels() {
        #expect(CategoryMapper.categoryFor(label: "building") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "temple") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "bridge") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "castle") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "monument") == .landmark)
        #expect(CategoryMapper.categoryFor(label: "museum") == .landmark)
    }

    @Test("unknown labels return nil")
    func unknownLabels() {
        #expect(CategoryMapper.categoryFor(label: "car") == nil)
        #expect(CategoryMapper.categoryFor(label: "unknown_thing") == nil)
        #expect(CategoryMapper.categoryFor(label: "text") == nil)
    }

    @Test("people labels map to people category")
    func peopleLabels() {
        #expect(CategoryMapper.categoryFor(label: "person") == .people)
        #expect(CategoryMapper.categoryFor(label: "portrait") == .people)
        #expect(CategoryMapper.categoryFor(label: "selfie") == .people)
    }

    @Test("labels are case insensitive")
    func caseInsensitive() {
        #expect(CategoryMapper.categoryFor(label: "FOOD") == .food)
        #expect(CategoryMapper.categoryFor(label: "Mountain") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "BUILDING") == .landmark)
    }

    @Test("compound labels match via contains")
    func compoundLabels() {
        #expect(CategoryMapper.categoryFor(label: "outdoor_mountain_snow") == .scenery)
        #expect(CategoryMapper.categoryFor(label: "food_pizza") == .food)
        #expect(CategoryMapper.categoryFor(label: "architecture_building") == .landmark)
    }
}

@Suite("CategoryMapper Observation Mapping Tests")
struct CategoryMapperObservationTests {
    @Test("maps highest confidence matching observation")
    func highestConfidence() {
        let observations = [
            makeObservation(identifier: "person", confidence: 0.9),
            makeObservation(identifier: "food", confidence: 0.7),
            makeObservation(identifier: "outdoor", confidence: 0.3),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .food)
        #expect(abs(result.confidence - 0.7) < 0.01)
    }

    @Test("person as main subject maps to people")
    func personMapsToPeople() {
        let observations = [
            makeObservation(identifier: "person", confidence: 0.9),
            makeObservation(identifier: "text", confidence: 0.1),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .people)
    }

    @Test("person with strong scenery prefers scenery")
    func personWithSceneryPrefersScenery() {
        let observations = [
            makeObservation(identifier: "person", confidence: 0.6),
            makeObservation(identifier: "landscape", confidence: 0.5),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .scenery)
    }

    @Test("unrecognized labels with decent confidence default to activity")
    func unknownDefaultsToActivity() {
        let observations = [
            makeObservation(identifier: "vehicle", confidence: 0.8),
            makeObservation(identifier: "text", confidence: 0.5),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .activity)
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

    @Test("prefers food over scenery when food is higher confidence")
    func categoryPriority() {
        let observations = [
            makeObservation(identifier: "food", confidence: 0.8),
            makeObservation(identifier: "outdoor", confidence: 0.6),
        ]

        let result = CategoryMapper.map(observations: observations)
        #expect(result.category == .food)
    }
}
