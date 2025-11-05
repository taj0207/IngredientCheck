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
        Logger.info("Fetching safety data for: \(identifier)", category: .echa)

        // Search for the substance (PubChem returns all data in one call)
        let substances = try await searchSubstance(query: identifier)

        guard let substance = substances.first else {
            Logger.logECHAQuery(ingredient: identifier, found: false)
            return nil
        }

        Logger.logECHAQuery(ingredient: identifier, found: true)

        // Parse safety info from PubChem GHS data
        if let ghsData = substance.ghsData {
            return parseSafetyInfoFromPubChem(substance: substance, ghsData: ghsData)
        }

        // If no GHS data available, return basic info
        return SafetyInfo(
            level: .unknown,
            hazardStatements: [],
            precautionaryStatements: [],
            ghsClassifications: [],
            regulatoryStatus: .notRegulated,
            lastUpdated: Date(),
            sources: ["PubChem"],
            detailedDescription: "No hazard classification available for \(substance.name)"
        )
    }

    /// Search for substances by name or identifier
    /// - Parameter query: Search query
    /// - Returns: Array of matching substances
    /// - Throws: NetworkError if search fails
    func searchSubstance(query: String) async throws -> [ECHASubstance] {
        // Route through Firebase proxy if enabled
        if APIConfig.useECHAProxy {
            return try await searchSubstanceViaProxy(query: query)
        }

        // Direct ECHA API call (will fail due to WAF)
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

    /// Search via Firebase proxy to bypass WAF
    private func searchSubstanceViaProxy(query: String) async throws -> [ECHASubstance] {
        guard let url = buildProxySearchURL(query: query) else {
            throw NetworkError.invalidURL
        }

        let request = networkClient.createRequest(url: url, method: .get)

        do {
            let response: ECHASearchResponse = try await networkClient.perform(
                request,
                decoding: ECHASearchResponse.self
            )

            Logger.info("ECHA proxy response received for '\(query)'", category: .echa)

            return response.substances
        } catch {
            Logger.error("ECHA proxy search failed for '\(query)'", error: error, category: .echa)
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

    /// Build Firebase proxy search URL
    private func buildProxySearchURL(query: String) -> URL? {
        guard var components = URLComponents(string: APIConfig.echaProxyURL) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "ingredient", value: query),
            URLQueryItem(name: "format", value: "json")
        ]

        return components.url
    }

    /// Build details URL
    private func buildDetailsURL(id: String) -> URL? {
        URL(string: "\(baseURL)/substance/\(id)")
    }

    /// Parse safety information from PubChem GHS data
    private func parseSafetyInfoFromPubChem(substance: ECHASubstance, ghsData: PubChemGHSData) -> SafetyInfo {
        // Parse hazard statements from PubChem
        let hazardStatements = parseHazardStatementsFromPubChem(ghsData.hazardStatements ?? [])

        // Parse GHS classifications from PubChem pictograms
        let ghsClassifications = parseGHSClassificationsFromPubChem(
            pictograms: ghsData.pictograms ?? [],
            signal: ghsData.signal
        )

        // Determine safety level
        let level = determineSafetyLevel(
            hazards: hazardStatements,
            classifications: ghsClassifications
        )

        return SafetyInfo(
            level: level,
            hazardStatements: hazardStatements,
            precautionaryStatements: ghsData.precautionaryStatements ?? [],
            ghsClassifications: ghsClassifications,
            regulatoryStatus: .notRegulated,
            lastUpdated: Date(),
            sources: ["PubChem"],
            detailedDescription: substance.molecularFormula
        )
    }

    /// Parse hazard statements from PubChem format
    private func parseHazardStatementsFromPubChem(_ statements: [String]) -> [HazardStatement] {
        return statements.compactMap { statement in
            // Extract H-code from statement (e.g., "H225: Highly Flammable...")
            guard let colonIndex = statement.firstIndex(of: ":"),
                  let code = statement.prefix(upTo: colonIndex).trimmingCharacters(in: .whitespaces).split(separator: " ").first else {
                return nil
            }

            let codeString = String(code)

            // Skip non-H codes
            guard codeString.hasPrefix("H") else { return nil }

            // Determine category from H-code
            let category: HazardStatement.HazardCategory
            if codeString.hasPrefix("H2") {
                category = .physical
            } else if codeString.hasPrefix("H3") {
                category = .health
            } else if codeString.hasPrefix("H4") {
                category = .environmental
            } else {
                category = .health
            }

            return HazardStatement(
                id: codeString,
                code: codeString,
                statement: statement,
                category: category
            )
        }
    }

    /// Parse GHS classifications from PubChem pictograms
    private func parseGHSClassificationsFromPubChem(pictograms: [PubChemPictogram], signal: String?) -> [GHSClassification] {
        // Remove duplicates by name
        let uniquePictograms = Dictionary(grouping: pictograms, by: { $0.name ?? "" })
            .compactMap { $0.value.first }

        return uniquePictograms.compactMap { pictogram in
            guard let name = pictogram.name,
                  let ghsPictogram = mapPubChemPictogramToGHS(name),
                  let signalWord = mapSignalWord(signal) else {
                return nil
            }

            return GHSClassification(
                id: name,
                pictogram: ghsPictogram,
                signalWord: signalWord,
                description: name
            )
        }
    }

    /// Map PubChem pictogram name to GHS pictogram enum
    private func mapPubChemPictogramToGHS(_ name: String) -> GHSClassification.GHSPictogram? {
        let lowercased = name.lowercased()

        if lowercased.contains("flammable") {
            return .flame
        } else if lowercased.contains("oxidizing") || lowercased.contains("oxidizer") {
            return .flameOverCircle
        } else if lowercased.contains("skull") || lowercased.contains("toxic") {
            return .skullCrossbones
        } else if lowercased.contains("health hazard") {
            return .healthHazard
        } else if lowercased.contains("corrosion") || lowercased.contains("corrosive") {
            return .corrosion
        } else if lowercased.contains("explod") || lowercased.contains("explosive") {
            return .exploding
        } else if lowercased.contains("gas") || lowercased.contains("cylinder") {
            return .gasContainer
        } else if lowercased.contains("environment") || lowercased.contains("aquatic") {
            return .environment
        } else if lowercased.contains("exclamation") || lowercased.contains("irritant") {
            return .exclamationMark
        }

        return nil
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
    let cid: Int?  // PubChem CID
    let molecularFormula: String?  // PubChem molecular formula
    let ghsData: PubChemGHSData?  // PubChem GHS safety data

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case casNumber = "cas"
        case ecNumber = "ec"
        case cid
        case molecularFormula
        case ghsData
    }
}

/// PubChem GHS Data
struct PubChemGHSData: Codable {
    let pictograms: [PubChemPictogram]?
    let signal: String?
    let hazardStatements: [String]?
    let precautionaryStatements: [String]?
}

/// PubChem Pictogram
struct PubChemPictogram: Codable {
    let name: String?
    let url: String?
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

// MARK: - Firebase Proxy Response Models

/// Firebase proxy response wrapper
private struct ECHAProxyResponse: Codable {
    let results: [ECHASubstance]?
    let cached: Bool?
    let cacheAge: Int?  // in minutes

    enum CodingKeys: String, CodingKey {
        case results
        case cached
        case cacheAge = "cache_age"
    }
}
