//
//  ECHAAPIClient.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Client for ECHA (European Chemicals Agency) API
/// Reference: https://echa.europa.eu/support/diss-dissemination-platform
class ECHAAPIClient {

    // MARK: - Properties

    private let networkClient: NetworkClient
    private let baseURL: String

    // MARK: - Initialization

    init(
        networkClient: NetworkClient = NetworkClient(),
        baseURL: String = APIConfig.echaDisseminationURL
    ) {
        self.networkClient = networkClient
        self.baseURL = baseURL
    }

    // MARK: - Public Methods

    /// Fetch safety information for an ingredient
    /// - Parameter identifier: Ingredient name, CAS number, or EC number
    /// - Returns: Safety information if found
    /// - Throws: RepositoryError if fetch fails
    func fetchSafetyInfo(for identifier: String) async throws -> SafetyInfo? {
        Logger.info("Fetching ECHA data for: \(identifier)", category: .echa)

        // First, search for the substance
        let substances = try await searchSubstance(query: identifier)

        guard let substance = substances.first else {
            Logger.logECHAQuery(ingredient: identifier, found: false)
            return nil
        }

        // Fetch detailed information
        let details = try await fetchSubstanceDetails(id: substance.id)

        Logger.logECHAQuery(ingredient: identifier, found: true)

        return parseSafetyInfo(from: details)
    }

    /// Search for substances by name or identifier
    /// - Parameter query: Search query
    /// - Returns: Array of matching substances
    /// - Throws: NetworkError if search fails
    func searchSubstance(query: String) async throws -> [ECHASubstance] {
        guard let url = buildSearchURL(query: query) else {
            throw NetworkError.invalidURL
        }

        let request = networkClient.createRequest(url: url, method: .get)

        do {
            let response: ECHASearchResponse = try await networkClient.perform(
                request,
                decoding: ECHASearchResponse.self
            )
            return response.substances
        } catch {
            Logger.error("ECHA search failed for '\(query)'", error: error, category: .echa)
            throw error
        }
    }

    /// Fetch detailed substance information
    /// - Parameter id: ECHA substance ID
    /// - Returns: Detailed substance data
    /// - Throws: NetworkError if fetch fails
    func fetchSubstanceDetails(id: String) async throws -> ECHASubstanceDetails {
        guard let url = buildDetailsURL(id: id) else {
            throw NetworkError.invalidURL
        }

        let request = networkClient.createRequest(url: url, method: .get)

        return try await networkClient.perform(
            request,
            decoding: ECHASubstanceDetails.self
        )
    }

    // MARK: - Private Methods

    /// Build search URL
    private func buildSearchURL(query: String) -> URL? {
        guard var components = URLComponents(string: "\(baseURL)/search") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "type", value: "substance"),
            URLQueryItem(name: "format", value: "json")
        ]

        return components.url
    }

    /// Build details URL
    private func buildDetailsURL(id: String) -> URL? {
        URL(string: "\(baseURL)/substance/\(id)")
    }

    /// Parse safety information from ECHA data
    private func parseSafetyInfo(from details: ECHASubstanceDetails) -> SafetyInfo {
        let hazardStatements = parseHazardStatements(from: details)
        let ghsClassifications = parseGHSClassifications(from: details)
        let level = determineSafetyLevel(
            hazards: hazardStatements,
            classifications: ghsClassifications
        )

        return SafetyInfo(
            level: level,
            hazardStatements: hazardStatements,
            precautionaryStatements: details.precautionaryStatements ?? [],
            ghsClassifications: ghsClassifications,
            regulatoryStatus: parseRegulatoryStatus(from: details),
            lastUpdated: Date(),
            sources: ["ECHA"],
            detailedDescription: details.description
        )
    }

    /// Parse hazard statements from ECHA data
    private func parseHazardStatements(from details: ECHASubstanceDetails) -> [HazardStatement] {
        guard let hazards = details.hazards else { return [] }

        return hazards.compactMap { hazard in
            guard let code = hazard.code,
                  let statement = hazard.statement else {
                return nil
            }

            let category: HazardStatement.HazardCategory
            if code.hasPrefix("H2") {
                category = .physical
            } else if code.hasPrefix("H3") {
                category = .health
            } else if code.hasPrefix("H4") {
                category = .environmental
            } else {
                category = .health
            }

            return HazardStatement(
                id: code,
                code: code,
                statement: statement,
                category: category
            )
        }
    }

    /// Parse GHS classifications
    private func parseGHSClassifications(from details: ECHASubstanceDetails) -> [GHSClassification] {
        guard let classifications = details.ghsClassifications else { return [] }

        return classifications.compactMap { classification in
            guard let pictogram = mapPictogram(classification.pictogram),
                  let signalWord = mapSignalWord(classification.signalWord) else {
                return nil
            }

            return GHSClassification(
                id: classification.id ?? UUID().uuidString,
                pictogram: pictogram,
                signalWord: signalWord,
                description: classification.description ?? ""
            )
        }
    }

    /// Map ECHA pictogram to GHS pictogram enum
    private func mapPictogram(_ name: String?) -> GHSClassification.GHSPictogram? {
        guard let name = name?.lowercased() else { return nil }

        if name.contains("flame") && name.contains("circle") {
            return .flameOverCircle
        } else if name.contains("flame") {
            return .flame
        } else if name.contains("skull") || name.contains("crossbones") {
            return .skullCrossbones
        } else if name.contains("health") {
            return .healthHazard
        } else if name.contains("corrosion") {
            return .corrosion
        } else if name.contains("explod") {
            return .exploding
        } else if name.contains("gas") {
            return .gasContainer
        } else if name.contains("environment") {
            return .environment
        } else if name.contains("exclamation") {
            return .exclamationMark
        }

        return nil
    }

    /// Map signal word string to enum
    private func mapSignalWord(_ word: String?) -> GHSClassification.SignalWord? {
        guard let word = word?.lowercased() else { return .none }

        if word.contains("danger") {
            return .danger
        } else if word.contains("warning") {
            return .warning
        } else {
            return .none
        }
    }

    /// Parse regulatory status
    private func parseRegulatoryStatus(from details: ECHASubstanceDetails) -> RegulatoryStatus {
        guard let status = details.regulatoryStatus?.lowercased() else {
            return .notRegulated
        }

        if status.contains("approved") {
            return .approved
        } else if status.contains("restricted") {
            return .restricted
        } else if status.contains("banned") || status.contains("prohibited") {
            return .banned
        } else if status.contains("review") {
            return .underReview
        } else {
            return .notRegulated
        }
    }

    /// Determine overall safety level
    private func determineSafetyLevel(
        hazards: [HazardStatement],
        classifications: [GHSClassification]
    ) -> Constants.SafetyLevel {
        // Check for severe hazards (H3xx series)
        let severeHazards = hazards.filter { hazard in
            let code = hazard.code
            return code.hasPrefix("H34") || // Genetic defects
                   code.hasPrefix("H35") || // Cancer
                   code.hasPrefix("H36") || // Reproductive toxicity
                   code.hasPrefix("H37")    // Organ damage
        }

        if !severeHazards.isEmpty {
            return .danger
        }

        // Check for danger signal word
        let hasDanger = classifications.contains { $0.signalWord == .danger }
        if hasDanger {
            return .danger
        }

        // Check for moderate hazards
        let moderateHazards = hazards.filter { hazard in
            hazard.code.hasPrefix("H3") // Health hazards
        }

        if !moderateHazards.isEmpty {
            return .warning
        }

        // Check for warning signal word
        let hasWarning = classifications.contains { $0.signalWord == .warning }
        if hasWarning {
            return .caution
        }

        // If no hazards, consider safe
        if hazards.isEmpty && classifications.isEmpty {
            return .safe
        }

        return .unknown
    }
}

// MARK: - ECHA Response Models

/// ECHA search response
private struct ECHASearchResponse: Codable {
    let substances: [ECHASubstance]

    enum CodingKeys: String, CodingKey {
        case substances = "results"
    }
}

/// ECHA substance (search result)
struct ECHASubstance: Codable {
    let id: String
    let name: String
    let casNumber: String?
    let ecNumber: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case casNumber = "cas"
        case ecNumber = "ec"
    }
}

/// ECHA substance details
struct ECHASubstanceDetails: Codable {
    let id: String
    let name: String
    let casNumber: String?
    let ecNumber: String?
    let description: String?
    let hazards: [ECHAHazard]?
    let precautionaryStatements: [String]?
    let ghsClassifications: [ECHAGHSClassification]?
    let regulatoryStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case casNumber = "cas"
        case ecNumber = "ec"
        case description
        case hazards = "hazardStatements"
        case precautionaryStatements = "pStatements"
        case ghsClassifications = "ghs"
        case regulatoryStatus = "status"
    }
}

/// ECHA hazard statement
struct ECHAHazard: Codable {
    let code: String?
    let statement: String?
}

/// ECHA GHS classification
struct ECHAGHSClassification: Codable {
    let id: String?
    let pictogram: String?
    let signalWord: String?
    let description: String?
}
