//
//  ScanResult.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import UIKit

/// Result of an ingredient list scan
struct ScanResult: Identifiable, Codable {

    // MARK: - Properties

    let id: UUID
    let ingredients: [Ingredient]
    let productName: String?
    let productBrand: String?
    let scanDate: Date
    let imageData: Data? // Stored image (optional)
    let overallSafetyLevel: Constants.SafetyLevel
    let ocrProvider: String
    let processingTime: TimeInterval

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        ingredients: [Ingredient],
        productName: String? = nil,
        productBrand: String? = nil,
        scanDate: Date = Date(),
        imageData: Data? = nil,
        ocrProvider: String = FeatureFlags.primaryOCRProvider.displayName,
        processingTime: TimeInterval = 0
    ) {
        self.id = id
        // Sort ingredients by safety level (worst to safest)
        self.ingredients = ingredients.sorted { lhs, rhs in
            ScanResult.safetyLevelPriority(lhs.safetyLevel) > ScanResult.safetyLevelPriority(rhs.safetyLevel)
        }
        self.productName = productName
        self.productBrand = productBrand
        self.scanDate = scanDate
        self.imageData = imageData
        self.ocrProvider = ocrProvider
        self.processingTime = processingTime

        // Calculate overall safety level
        self.overallSafetyLevel = ScanResult.calculateOverallSafety(from: ingredients)
    }

    // MARK: - Computed Properties

    /// Number of ingredients found
    var ingredientCount: Int {
        ingredients.count
    }

    /// Number of ingredients with concerns
    var concernCount: Int {
        ingredients.filter { $0.hasConcerns }.count
    }

    /// Has any safety concerns
    var hasConcerns: Bool {
        concernCount > 0
    }

    /// Product display name
    var displayName: String {
        if let name = productName {
            return name
        } else if let brand = productBrand {
            return brand
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: scanDate)
        }
    }

    /// Summary text
    var summary: String {
        if hasConcerns {
            return String(
                format: NSLocalizedString("scan.summary.concerns", comment: "%d concern(s) in %d ingredients"),
                concernCount,
                ingredientCount
            )
        } else {
            return String(
                format: NSLocalizedString("scan.summary.safe", comment: "All %d ingredients appear safe"),
                ingredientCount
            )
        }
    }

    /// Ingredients grouped by safety level
    var ingredientsBySafetyLevel: [Constants.SafetyLevel: [Ingredient]] {
        Dictionary(grouping: ingredients) { $0.safetyLevel }
    }

    // MARK: - Helper Methods

    /// Calculate overall safety level from ingredients
    private static func calculateOverallSafety(from ingredients: [Ingredient]) -> Constants.SafetyLevel {
        guard !ingredients.isEmpty else { return .unknown }

        // If any ingredient is dangerous, overall is danger
        if ingredients.contains(where: { $0.safetyLevel == .danger }) {
            return .danger
        }

        // If any ingredient has warning, overall is warning
        if ingredients.contains(where: { $0.safetyLevel == .warning }) {
            return .warning
        }

        // If any ingredient requires caution, overall is caution
        if ingredients.contains(where: { $0.safetyLevel == .caution }) {
            return .caution
        }

        // If all ingredients are safe
        if ingredients.allSatisfy({ $0.safetyLevel == .safe }) {
            return .safe
        }

        // Otherwise unknown
        return .unknown
    }

    /// Get priority for sorting (higher = more dangerous)
    private static func safetyLevelPriority(_ level: Constants.SafetyLevel) -> Int {
        switch level {
        case .danger: return 4
        case .warning: return 3
        case .caution: return 2
        case .unknown: return 1
        case .safe: return 0
        }
    }
}

// MARK: - Codable Conformance

extension ScanResult {
    enum CodingKeys: String, CodingKey {
        case id
        case ingredients
        case productName
        case productBrand
        case scanDate
        case imageData
        case overallSafetyLevel
        case ocrProvider
        case processingTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        productBrand = try container.decodeIfPresent(String.self, forKey: .productBrand)
        scanDate = try container.decode(Date.self, forKey: .scanDate)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        ocrProvider = try container.decode(String.self, forKey: .ocrProvider)
        processingTime = try container.decode(TimeInterval.self, forKey: .processingTime)

        // Recalculate overall safety level
        overallSafetyLevel = ScanResult.calculateOverallSafety(from: ingredients)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encodeIfPresent(productBrand, forKey: .productBrand)
        try container.encode(scanDate, forKey: .scanDate)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encode(overallSafetyLevel, forKey: .overallSafetyLevel)
        try container.encode(ocrProvider, forKey: .ocrProvider)
        try container.encode(processingTime, forKey: .processingTime)
    }
}

// MARK: - Sample Data

extension ScanResult {
    static let sample = ScanResult(
        ingredients: [
            Ingredient.sampleSafe,
            Ingredient.sampleWarning,
            Ingredient.sampleDanger
        ],
        productName: "Sample Moisturizer",
        productBrand: "Sample Brand",
        processingTime: 2.5
    )

    static let sampleSafe = ScanResult(
        ingredients: [Ingredient.sampleSafe],
        productName: "Safe Product",
        productBrand: "Good Brand"
    )
}
