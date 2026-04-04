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
        "food", "pizza", "sushi", "coffee", "restaurant", "cafe", "diner",
        "meal", "dessert", "cake", "fruit", "vegetable", "beer",
        "wine", "cooking", "kitchen", "bread", "pasta", "rice",
        "meat", "fish", "seafood", "salad", "soup", "tea",
        "cocktail", "bakery", "brunch", "breakfast", "lunch", "dinner",
        "candy", "chocolate", "snack", "grill", "barbecue",
        "noodle", "ramen", "taco", "burger", "steak", "curry",
        "waffle", "pancake", "donut", "doughnut", "pastry",
        "drink", "ice_cream", "takeout", "appetizer", "entree",
        "sashimi", "tempura", "dumpling", "dim_sum", "gyoza", "pho",
        "pad_thai", "bibimbap", "kimchi", "miso", "tofu",
        "croissant", "bagel", "muffin", "scone", "biscuit",
        "pie", "tart", "brownie", "cookie", "macaron",
        "gelato", "sorbet", "yogurt", "smoothie", "juice",
        "espresso", "latte", "cappuccino", "matcha", "boba",
        "whiskey", "sake", "vodka", "gin", "rum", "champagne",
        "burrito", "quesadilla", "enchilada", "nachos", "falafel",
        "kebab", "shawarma", "hummus", "pita",
        "sandwich", "wrap", "panini", "hotdog", "corndog",
        "sausage", "bacon", "egg", "omelet", "omelette", "crepe",
        "wonton", "spring_roll", "egg_roll", "satay", "laksa",
        "risotto", "gnocchi", "ravioli", "lasagna", "bolognese",
        "ceviche", "paella", "tapas", "charcuterie", "fondue",
        "poutine", "okonomiyaki", "takoyaki", "katsu", "tonkatsu",
        "teriyaki", "yakitori", "udon", "soba", "dango", "mochi",
        "bento", "onigiri", "nigiri", "maki", "roll",
        "chowder", "stew", "broth", "bisque", "congee", "porridge",
        "cheese", "butter", "cream", "sauce", "gravy", "dip",
        "chip", "pretzel", "popcorn", "cracker",
        "grocery", "produce", "deli", "buffet", "feast",
        "plate", "bowl", "dish", "platter", "tray",
        "food_box", "food_in_box", "food_in_container",
        "dessert_in_box", "pastry_in_box", "food_in_bag",
        "pastry_in_bag", "dessert_in_bag", "lunchbox",
        "bento_box", "takeout_box", "takeout_bag", "doggy_bag",
        "food_truck", "food_stall", "food_court", "food_hall",
        "menu", "recipe", "ingredient", "scone", "croissant",
    ]

    private static let sceneryKeywords: Set<String> = [
        "landscape", "mountain", "beach", "ocean", "lake", "forest",
        "sunset", "sunrise", "river", "waterfall", "desert",
        "meadow", "valley", "island", "coast", "cliff", "glacier",
        "volcano", "countryside", "panorama", "horizon",
        "wilderness", "rainbow", "aurora", "canyon", "reef",
    ]

    private static let landmarkKeywords: Set<String> = [
        "monument", "temple", "church", "cathedral",
        "castle", "museum", "statue", "lighthouse",
        "palace", "ruins", "pagoda", "pyramid",
        "mosque", "shrine", "memorial", "capitol",
        "colosseum", "minaret", "obelisk",
    ]

    private static let peopleKeywords: Set<String> = [
        "person", "people", "face", "portrait", "selfie", "family",
        "couple", "child", "baby", "smile", "posing", "friend", "friends"
    ]

    private static let activityKeywords: Set<String> = [
        "sport", "hiking", "swimming", "skiing", "surfing",
        "cycling", "running", "climbing", "diving", "kayak",
        "dance", "yoga", "fishing", "camping", "concert",
        "festival", "market", "shopping",
    ]

    private static let foodConfidenceMin: Float = 0.15
    private static let categoryConfidenceMin: Float = 0.25
    private static let peopleConfidenceMin: Float = 0.30

    static func categoryFor(label: String) -> PhotoCategory? {
        let lower = label.lowercased()
        let words = Set(lower.split(whereSeparator: { !$0.isLetter }).map(String.init))

        for keyword in foodKeywords where lower.contains(keyword) {
            return .food
        }
        for keyword in landmarkKeywords where words.contains(keyword) {
            return .landmark
        }
        for keyword in sceneryKeywords where words.contains(keyword) {
            return .scenery
        }
        for keyword in peopleKeywords where words.contains(keyword) {
            return .people
        }
        for keyword in activityKeywords where words.contains(keyword) {
            return .activity
        }
        return nil
    }

    static func map(observations: [VNClassificationObservation]) -> ClassificationResult {
        let sorted = observations.sorted { $0.confidence > $1.confidence }

        var bestFood: Float = 0
        var bestScenery: Float = 0
        var bestLandmark: Float = 0
        var bestPeople: Float = 0
        var bestActivity: Float = 0

        for observation in sorted {
            guard let category = categoryFor(label: observation.identifier) else { continue }
            switch category {
            case .food: bestFood = max(bestFood, observation.confidence)
            case .scenery: bestScenery = max(bestScenery, observation.confidence)
            case .landmark: bestLandmark = max(bestLandmark, observation.confidence)
            case .people: bestPeople = max(bestPeople, observation.confidence)
            case .activity: bestActivity = max(bestActivity, observation.confidence)
            case .miscellaneous: break
            }
        }

        if bestFood >= foodConfidenceMin {
            return ClassificationResult(category: .food, confidence: Double(bestFood))
        }

        if bestLandmark >= categoryConfidenceMin {
            return ClassificationResult(category: .landmark, confidence: Double(bestLandmark))
        }

        if bestScenery >= categoryConfidenceMin {
            return ClassificationResult(category: .scenery, confidence: Double(bestScenery))
        }

        if bestActivity >= categoryConfidenceMin {
            return ClassificationResult(category: .activity, confidence: Double(bestActivity))
        }

        if bestPeople >= peopleConfidenceMin {
            return ClassificationResult(category: .people, confidence: Double(bestPeople))
        }

        return ClassificationResult(category: .miscellaneous, confidence: Double(sorted.first?.confidence ?? 0))
    }
}
