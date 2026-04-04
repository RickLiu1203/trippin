//
//  CategoryMapper.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Foundation
import Vision

struct ClassificationResult: Sendable, Equatable {
    let category: PhotoCategory
    let confidence: Double
}

enum CategoryMapper {
    private static let foodKeywords: Set<String> = [
        "food", "drink", "pizza", "sushi", "coffee", "restaurant",
        "meal", "dessert", "cake", "fruit", "vegetable", "beer",
        "wine", "cooking", "kitchen", "bread", "pasta", "rice",
        "meat", "fish", "seafood", "salad", "soup", "tea",
        "cocktail", "bakery", "brunch", "breakfast", "lunch", "dinner",
        "candy", "chocolate", "ice_cream", "snack", "grill", "barbecue",
    ]

    private static let sceneryKeywords: Set<String> = [
        "landscape", "mountain", "beach", "ocean", "lake", "forest",
        "sunset","sunrise", "nature", "river",
        "waterfall", "snow", "cloud", "desert", "field",
        "meadow", "valley", "island", "coast", "cliff", "glacier",
        "volcano", "countryside", "rural", "panorama", "horizon",
        "wilderness", "rainbow", "fog", "aurora",
    ]

    private static let landmarkKeywords: Set<String> = [
        "building", "monument", "temple", "church",
        "bridge", "tower", "castle", "museum", "statue", "cathedral",
        "palace", "ruins", "skyscraper", "lighthouse", "fountain",
        "plaza", "gate", "arch", "dome", "pagoda", "pyramid",
        "mosque", "shrine", "memorial", "capitol", "library", "temple"
    ]

    private static let peopleKeywords: Set<String> = [
        "person", "people", "face", "portrait", "selfie", "group",
        "crowd", "family", "couple", "child", "baby", "man", "woman",
        "smile", "posing",
    ]

    private static let confidenceThreshold: Double = 0.15

    static func categoryFor(label: String) -> PhotoCategory? {
        let lower = label.lowercased()
        for keyword in foodKeywords where lower.contains(keyword) {
            return .food
        }
        for keyword in landmarkKeywords where lower.contains(keyword) {
            return .landmark
        }
        for keyword in sceneryKeywords where lower.contains(keyword) {
            return .scenery
        }
        for keyword in peopleKeywords where lower.contains(keyword) {
            return .people
        }
        return nil
    }

    static func map(observations: [VNClassificationObservation]) -> ClassificationResult {
        let sorted = observations.sorted { $0.confidence > $1.confidence }

        var peopleScore: Float = 0
        var bestNonPeople: (PhotoCategory, Float)?

        for observation in sorted {
            guard let category = categoryFor(label: observation.identifier) else { continue }
            if category == .people {
                peopleScore = max(peopleScore, observation.confidence)
            } else if bestNonPeople == nil {
                bestNonPeople = (category, observation.confidence)
            }
        }

        if let (nonPeopleCat, nonPeopleConf) = bestNonPeople, nonPeopleConf > peopleScore * 0.5 {
            return ClassificationResult(category: nonPeopleCat, confidence: Double(nonPeopleConf))
        }

        if peopleScore > Float(confidenceThreshold) {
            return ClassificationResult(category: .people, confidence: Double(peopleScore))
        }

        if let (cat, conf) = bestNonPeople {
            return ClassificationResult(category: cat, confidence: Double(conf))
        }

        for observation in sorted where observation.confidence > Float(confidenceThreshold) {
            return ClassificationResult(category: .activity, confidence: Double(observation.confidence))
        }

        return ClassificationResult(category: .miscellaneous, confidence: Double(sorted.first?.confidence ?? 0))
    }
}
