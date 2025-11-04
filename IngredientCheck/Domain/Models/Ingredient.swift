//
//  Ingredient.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Core ingredient model
struct Ingredient: Identifiable, Codable, Hashable {

    // MARK: - Properties

    let id: UUID
    let name: String
    let alternativeNames: [String]
    let casNumber: String? // CAS Registry Number
    let ecNumber: String? // EC Number (European Community number)
    let safetyInfo: SafetyInfo?
    let category: IngredientCategory?
    let dateAdded: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        alternativeNames: [String] = [],
        casNumber: String? = nil,
        ecNumber: String? = nil,
        safetyInfo: SafetyInfo? = nil,
        category: IngredientCategory? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.alternativeNames = alternativeNames
        self.casNumber = casNumber
        self.ecNumber = ecNumber
        self.safetyInfo = safetyInfo
        self.category = category
        self.dateAdded = dateAdded
    }

    // MARK: - Computed Properties

    /// Display name (uses alternative name if available)
    var displayName: String {
        name
    }

    /// Unique identifier for ECHA queries (prefers CAS number)
    var searchIdentifier: String {
        casNumber ?? ecNumber ?? name
    }

    /// Safety level
    var safetyLevel: Constants.SafetyLevel {
        safetyInfo?.level ?? .unknown
    }

    /// Has safety concerns
    var hasConcerns: Bool {
        switch safetyLevel {
        case .safe, .unknown:
            return false
        case .caution, .warning, .danger:
            return true
        }
    }
}

// MARK: - Ingredient Category

enum IngredientCategory: String, Codable, CaseIterable {
    case preservative = "preservative"
    case fragrance = "fragrance"
    case colorant = "colorant"
    case emulsifier = "emulsifier"
    case surfactant = "surfactant"
    case moisturizer = "moisturizer"
    case antioxidant = "antioxidant"
    case uvFilter = "uv_filter"
    case acidityRegulator = "acidity_regulator"
    case thickener = "thickener"
    case solvent = "solvent"
    case other = "other"

    var localizedName: String {
        switch self {
        case .preservative:
            return NSLocalizedString("ingredient.category.preservative", comment: "Preservative")
        case .fragrance:
            return NSLocalizedString("ingredient.category.fragrance", comment: "Fragrance")
        case .colorant:
            return NSLocalizedString("ingredient.category.colorant", comment: "Colorant")
        case .emulsifier:
            return NSLocalizedString("ingredient.category.emulsifier", comment: "Emulsifier")
        case .surfactant:
            return NSLocalizedString("ingredient.category.surfactant", comment: "Surfactant")
        case .moisturizer:
            return NSLocalizedString("ingredient.category.moisturizer", comment: "Moisturizer")
        case .antioxidant:
            return NSLocalizedString("ingredient.category.antioxidant", comment: "Antioxidant")
        case .uvFilter:
            return NSLocalizedString("ingredient.category.uv_filter", comment: "UV Filter")
        case .acidityRegulator:
            return NSLocalizedString("ingredient.category.acidity_regulator", comment: "Acidity Regulator")
        case .thickener:
            return NSLocalizedString("ingredient.category.thickener", comment: "Thickener")
        case .solvent:
            return NSLocalizedString("ingredient.category.solvent", comment: "Solvent")
        case .other:
            return NSLocalizedString("ingredient.category.other", comment: "Other")
        }
    }
}

// MARK: - Sample Data

extension Ingredient {
    static let sampleSafe = Ingredient(
        name: "Glycerin",
        alternativeNames: ["Glycerol", "Propane-1,2,3-triol"],
        casNumber: "56-81-5",
        safetyInfo: SafetyInfo.sampleSafe,
        category: .moisturizer
    )

    static let sampleWarning = Ingredient(
        name: "Phenoxyethanol",
        alternativeNames: ["2-Phenoxyethanol"],
        casNumber: "122-99-6",
        safetyInfo: SafetyInfo.sampleWarning,
        category: .preservative
    )

    static let sampleDanger = Ingredient(
        name: "Benzene",
        alternativeNames: [],
        casNumber: "71-43-2",
        safetyInfo: SafetyInfo.sampleDanger,
        category: .solvent
    )

    static let samples = [sampleSafe, sampleWarning, sampleDanger]
}
