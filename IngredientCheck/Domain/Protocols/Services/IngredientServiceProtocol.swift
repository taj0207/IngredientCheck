//
//  IngredientServiceProtocol.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Protocol for ingredient safety checking service
protocol IngredientServiceProtocol {

    /// Check safety information for an ingredient
    /// - Parameter ingredientName: Name of the ingredient to check
    /// - Returns: Safety information if found, nil otherwise
    /// - Throws: IngredientServiceError if check fails
    func checkSafety(for ingredientName: String) async throws -> SafetyInfo?

    /// Check safety for multiple ingredients
    /// - Parameter ingredientNames: Array of ingredient names
    /// - Returns: Array of ingredients with safety info
    /// - Throws: IngredientServiceError if check fails
    func checkSafety(for ingredientNames: [String]) async throws -> [Ingredient]

    /// Search for ingredient by name or identifier
    /// - Parameter query: Search query (name, CAS number, EC number)
    /// - Returns: Array of matching ingredients
    /// - Throws: IngredientServiceError if search fails
    func searchIngredient(query: String) async throws -> [Ingredient]

    /// Get detailed information for an ingredient
    /// - Parameter identifier: Ingredient identifier (CAS, EC, or name)
    /// - Returns: Detailed ingredient information
    /// - Throws: IngredientServiceError if fetch fails
    func getIngredientDetails(identifier: String) async throws -> Ingredient?
}

// MARK: - Ingredient Service Errors

enum IngredientServiceError: LocalizedError {
    case notFound(String)
    case invalidIdentifier(String)
    case databaseUnavailable
    case networkError(Error)
    case parsingError(String)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .notFound(let ingredient):
            return String(format: NSLocalizedString("ingredient.error.not_found", comment: "Ingredient '%@' not found"), ingredient)
        case .invalidIdentifier(let id):
            return String(format: NSLocalizedString("ingredient.error.invalid_id", comment: "Invalid identifier: %@"), id)
        case .databaseUnavailable:
            return NSLocalizedString("ingredient.error.database_unavailable", comment: "Safety database temporarily unavailable")
        case .networkError(let error):
            return String(format: NSLocalizedString("ingredient.error.network", comment: "Network error: %@"), error.localizedDescription)
        case .parsingError(let message):
            return String(format: NSLocalizedString("ingredient.error.parsing", comment: "Failed to parse data: %@"), message)
        case .unknownError(let error):
            return error.localizedDescription
        }
    }
}
