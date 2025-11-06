//
//  RegulatorySubstance.swift
//  IngredientCheck
//
//  Created on 2025-11-05
//

import Foundation

// Note: RegulatoryStatus is defined in SafetyInfo.swift
// Logger is defined in Logger.swift

/// ECHA Regulatory Database
struct ECHARegulatoryDatabase: Codable {
    let version: String
    let lastUpdated: String
    let source: String
    let substances: [RegulatorySubstance]
}

/// Regulatory substance from ECHA lists
struct RegulatorySubstance: Codable, Identifiable {
    let id = UUID()
    let name: String
    let casNumber: String?
    let ecNumber: String?
    let regulatoryStatus: String  // "BANNED", "RESTRICTED", "SVHC"
    let list: String  // "Annex XVII", "Candidate List", etc.
    let category: String
    let restrictions: String
    let hazards: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case casNumber
        case ecNumber
        case regulatoryStatus
        case list
        case category
        case restrictions
        case hazards
    }

    /// Convert regulatory status string to enum
    var status: RegulatoryStatus {
        switch regulatoryStatus.uppercased() {
        case "BANNED":
            return .banned
        case "RESTRICTED":
            return .restricted
        case "SVHC":
            return .underReview
        default:
            return .notRegulated
        }
    }

    /// Check if substance matches an ingredient name (case-insensitive, partial match)
    func matches(ingredient: String) -> Bool {
        let cleanIngredient = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.lowercased()

        // Exact match
        if cleanName == cleanIngredient {
            return true
        }

        // Contains match (e.g., "benzene" matches "sodium benzene sulfonate")
        if cleanIngredient.contains(cleanName) || cleanName.contains(cleanIngredient) {
            return true
        }

        // CAS number match
        if let cas = casNumber, cas.lowercased() == cleanIngredient {
            return true
        }

        // EC number match
        if let ec = ecNumber, ec.lowercased() == cleanIngredient {
            return true
        }

        return false
    }
}

/// Manager for ECHA regulatory database
actor ECHARegulatoryManager {
    static let shared = ECHARegulatoryManager()

    private var database: ECHARegulatoryDatabase?
    private var isLoaded = false

    private init() {}

    /// Load regulatory database from JSON file
    func loadDatabase() async throws {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: "ECHA_Regulatory_Data", withExtension: "json") else {
            Logger.error("ECHA_Regulatory_Data.json not found in bundle", category: .echa)
            throw DataError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        database = try decoder.decode(ECHARegulatoryDatabase.self, from: data)
        isLoaded = true

        Logger.info("Loaded \(database?.substances.count ?? 0) ECHA regulatory substances", category: .echa)
    }

    /// Find regulatory information for an ingredient
    func findRegulatory(for ingredient: String) async -> RegulatorySubstance? {
        // Load database if not already loaded
        if !isLoaded {
            try? await loadDatabase()
        }

        guard let database = database else { return nil }

        // Search for matching substance
        return database.substances.first { substance in
            substance.matches(ingredient: ingredient)
        }
    }

    /// Check if ingredient is banned or restricted
    func getRegulatoryStatus(for ingredient: String) async -> RegulatoryStatus {
        if let substance = await findRegulatory(for: ingredient) {
            return substance.status
        }
        return .notRegulated
    }

    /// Get all substances for a specific status
    func getSubstances(withStatus status: RegulatoryStatus) async -> [RegulatorySubstance] {
        if !isLoaded {
            try? await loadDatabase()
        }

        guard let database = database else { return [] }

        return database.substances.filter { $0.status == status }
    }
}

/// Data error types
enum DataError: Error {
    case fileNotFound
    case invalidFormat
}
