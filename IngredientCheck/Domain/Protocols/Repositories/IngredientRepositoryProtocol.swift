//
//  IngredientRepositoryProtocol.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Repository protocol for ingredient data access
/// This abstraction allows easy switching between direct ECHA API and backend API
protocol IngredientRepositoryProtocol {

    /// Fetch safety information for an ingredient
    /// - Parameter identifier: Ingredient name, CAS number, or EC number
    /// - Returns: Safety information if found
    /// - Throws: RepositoryError if fetch fails
    func fetchSafetyInfo(for identifier: String) async throws -> SafetyInfo?

    /// Fetch safety information for multiple ingredients
    /// - Parameter identifiers: Array of ingredient identifiers
    /// - Returns: Dictionary mapping identifiers to safety info
    /// - Throws: RepositoryError if fetch fails
    func fetchSafetyInfo(for identifiers: [String]) async throws -> [String: SafetyInfo]

    /// Search ingredients by query
    /// - Parameter query: Search query
    /// - Returns: Array of matching ingredients
    /// - Throws: RepositoryError if search fails
    func searchIngredients(query: String) async throws -> [Ingredient]

    /// Fetch detailed ingredient information
    /// - Parameter identifier: Ingredient identifier
    /// - Returns: Complete ingredient object
    /// - Throws: RepositoryError if fetch fails
    func fetchIngredient(identifier: String) async throws -> Ingredient?

    /// Clear local cache
    func clearCache() async throws
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case dataNotFound
    case invalidData(String)
    case cacheError(Error)
    case networkError(Error)
    case databaseError(Error)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return NSLocalizedString("repository.error.not_found", comment: "Data not found")
        case .invalidData(let message):
            return String(format: NSLocalizedString("repository.error.invalid_data", comment: "Invalid data: %@"), message)
        case .cacheError(let error):
            return String(format: NSLocalizedString("repository.error.cache", comment: "Cache error: %@"), error.localizedDescription)
        case .networkError(let error):
            return String(format: NSLocalizedString("repository.error.network", comment: "Network error: %@"), error.localizedDescription)
        case .databaseError(let error):
            return String(format: NSLocalizedString("repository.error.database", comment: "Database error: %@"), error.localizedDescription)
        case .unknownError(let error):
            return error.localizedDescription
        }
    }
}
