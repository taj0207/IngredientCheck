//
//  SafetyInfo.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Safety information for an ingredient from ECHA and other databases
struct SafetyInfo: Codable, Hashable {

    // MARK: - Properties

    let level: Constants.SafetyLevel
    let hazardStatements: [HazardStatement]
    let precautionaryStatements: [String]
    let ghsClassifications: [GHSClassification]
    let regulatoryStatus: RegulatoryStatus
    let lastUpdated: Date
    let sources: [String]
    let detailedDescription: String?

    // MARK: - Initialization

    init(
        level: Constants.SafetyLevel,
        hazardStatements: [HazardStatement] = [],
        precautionaryStatements: [String] = [],
        ghsClassifications: [GHSClassification] = [],
        regulatoryStatus: RegulatoryStatus = .notRegulated,
        lastUpdated: Date = Date(),
        sources: [String] = ["ECHA"],
        detailedDescription: String? = nil
    ) {
        self.level = level
        self.hazardStatements = hazardStatements
        self.precautionaryStatements = precautionaryStatements
        self.ghsClassifications = ghsClassifications
        self.regulatoryStatus = regulatoryStatus
        self.lastUpdated = lastUpdated
        self.sources = sources
        self.detailedDescription = detailedDescription
    }

    // MARK: - Computed Properties

    /// Has any hazards
    var hasHazards: Bool {
        !hazardStatements.isEmpty || !ghsClassifications.isEmpty
    }

    /// Short summary for UI
    var summary: String {
        if hazardStatements.isEmpty {
            return NSLocalizedString("safety.no_hazards", comment: "No known hazards")
        } else {
            let count = hazardStatements.count
            return String(format: NSLocalizedString("safety.hazards_count", comment: "%d hazard(s) identified"), count)
        }
    }
}

// MARK: - Hazard Statement

/// H-statement from GHS/CLP classification
struct HazardStatement: Codable, Hashable, Identifiable {
    let id: String // e.g., "H302"
    let code: String // e.g., "H302"
    let statement: String // e.g., "Harmful if swallowed"
    let category: HazardCategory

    enum HazardCategory: String, Codable {
        case physical = "physical"
        case health = "health"
        case environmental = "environmental"

        var localizedName: String {
            switch self {
            case .physical:
                return NSLocalizedString("hazard.category.physical", comment: "Physical Hazard")
            case .health:
                return NSLocalizedString("hazard.category.health", comment: "Health Hazard")
            case .environmental:
                return NSLocalizedString("hazard.category.environmental", comment: "Environmental Hazard")
            }
        }
    }
}

// MARK: - GHS Classification

/// Globally Harmonized System of Classification and Labelling
struct GHSClassification: Codable, Hashable, Identifiable {
    let id: String
    let pictogram: GHSPictogram
    let signalWord: SignalWord
    let description: String

    enum GHSPictogram: String, Codable {
        case exploding = "exploding_bomb"
        case flame = "flame"
        case flameOverCircle = "flame_over_circle"
        case gasContainer = "gas_container"
        case corrosion = "corrosion"
        case skullCrossbones = "skull_crossbones"
        case healthHazard = "health_hazard"
        case exclamationMark = "exclamation_mark"
        case environment = "environment"

        var sfSymbol: String {
            switch self {
            case .exploding: return "burst.fill"
            case .flame: return "flame.fill"
            case .flameOverCircle: return "sun.max.fill"
            case .gasContainer: return "cylinder.fill"
            case .corrosion: return "drop.triangle.fill"
            case .skullCrossbones: return "xmark.seal.fill"
            case .healthHazard: return "staroflife.fill"
            case .exclamationMark: return "exclamationmark.triangle.fill"
            case .environment: return "leaf.fill"
            }
        }
    }

    enum SignalWord: String, Codable {
        case danger = "danger"
        case warning = "warning"
        case none = "none"

        var localizedString: String {
            switch self {
            case .danger: return NSLocalizedString("signal.danger", comment: "DANGER")
            case .warning: return NSLocalizedString("signal.warning", comment: "WARNING")
            case .none: return ""
            }
        }
    }
}

// MARK: - Regulatory Status

enum RegulatoryStatus: String, Codable {
    case approved = "approved"
    case restricted = "restricted"
    case banned = "banned"
    case underReview = "under_review"
    case notRegulated = "not_regulated"

    var localizedName: String {
        switch self {
        case .approved:
            return NSLocalizedString("regulatory.approved", comment: "Approved")
        case .restricted:
            return NSLocalizedString("regulatory.restricted", comment: "Restricted in EU")
        case .banned:
            return NSLocalizedString("regulatory.banned", comment: "Banned in EU")
        case .underReview:
            return NSLocalizedString("regulatory.under_review", comment: "SVHC (Under Review)")
        case .notRegulated:
            return NSLocalizedString("regulatory.not_regulated", comment: "Not Regulated")
        }
    }

    /// Badge icon for UI
    var badgeIcon: String {
        switch self {
        case .approved: return "checkmark.seal.fill"
        case .restricted: return "exclamationmark.triangle.fill"
        case .banned: return "xmark.octagon.fill"
        case .underReview: return "exclamationmark.circle.fill"
        case .notRegulated: return "info.circle"
        }
    }

    /// Badge color for UI (SwiftUI Color name)
    var badgeColorName: String {
        switch self {
        case .approved: return "green"
        case .restricted: return "orange"
        case .banned: return "red"
        case .underReview: return "yellow"
        case .notRegulated: return "gray"
        }
    }

    /// Whether this status should be prominently displayed
    var shouldHighlight: Bool {
        switch self {
        case .banned, .restricted, .underReview:
            return true
        case .approved, .notRegulated:
            return false
        }
    }

    /// EU-specific regulatory description
    var euDescription: String {
        switch self {
        case .approved:
            return "Approved for use in EU consumer products"
        case .restricted:
            return "Restricted under EU REACH Annex XVII - Limited use conditions apply"
        case .banned:
            return "Banned in EU consumer products under REACH regulations"
        case .underReview:
            return "SVHC - Substance of Very High Concern on EU Candidate List"
        case .notRegulated:
            return "No specific EU REACH restrictions"
        }
    }
}

// MARK: - Sample Data

extension SafetyInfo {
    static let sampleSafe = SafetyInfo(
        level: .safe,
        hazardStatements: [],
        precautionaryStatements: ["Keep out of reach of children"],
        ghsClassifications: [],
        regulatoryStatus: .approved,
        detailedDescription: "Widely used moisturizer, considered safe for cosmetic use."
    )

    static let sampleWarning = SafetyInfo(
        level: .warning,
        hazardStatements: [
            HazardStatement(
                id: "H302",
                code: "H302",
                statement: "Harmful if swallowed",
                category: .health
            )
        ],
        precautionaryStatements: [
            "Avoid contact with skin and eyes",
            "Wash hands thoroughly after handling"
        ],
        ghsClassifications: [
            GHSClassification(
                id: "GHS07",
                pictogram: .exclamationMark,
                signalWord: .warning,
                description: "Irritant"
            )
        ],
        regulatoryStatus: .restricted,
        detailedDescription: "Common preservative. May cause skin irritation in sensitive individuals."
    )

    static let sampleDanger = SafetyInfo(
        level: .danger,
        hazardStatements: [
            HazardStatement(
                id: "H350",
                code: "H350",
                statement: "May cause cancer",
                category: .health
            ),
            HazardStatement(
                id: "H340",
                code: "H340",
                statement: "May cause genetic defects",
                category: .health
            )
        ],
        precautionaryStatements: [
            "Do not breathe vapor",
            "Wear protective gloves/clothing",
            "IF exposed: Call a POISON CENTER/doctor"
        ],
        ghsClassifications: [
            GHSClassification(
                id: "GHS08",
                pictogram: .healthHazard,
                signalWord: .danger,
                description: "Carcinogen"
            )
        ],
        regulatoryStatus: .banned,
        sources: ["ECHA", "IARC"],
        detailedDescription: "Highly toxic substance. Known carcinogen. Banned in cosmetics and consumer products."
    )
}
