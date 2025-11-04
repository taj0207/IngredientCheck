//
//  IngredientServiceImpl.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Implementation of ingredient safety checking service
class IngredientServiceImpl: IngredientServiceProtocol {

    // MARK: - Properties

    private let repository: IngredientRepositoryProtocol

    // MARK: - Initialization

    init(repository: IngredientRepositoryProtocol = IngredientRepositoryImpl()) {
        self.repository = repository
    }

    // MARK: - IngredientServiceProtocol

    func checkSafety(for ingredientName: String) async throws -> SafetyInfo? {
        Logger.info("Checking safety for: \(ingredientName)", category: .echa)

        do {
            return try await repository.fetchSafetyInfo(for: ingredientName)
        } catch {
            Logger.error("Safety check failed for '\(ingredientName)'", error: error, category: .echa)
            throw IngredientServiceError.networkError(error)
        }
    }

    func checkSafety(for ingredientNames: [String]) async throws -> [Ingredient] {
        Logger.info("Checking safety for \(ingredientNames.count) ingredients", category: .echa)

        do {
            let safetyInfoDict = try await repository.fetchSafetyInfo(for: ingredientNames)

            return ingredientNames.map { name in
                Ingredient(
                    name: name,
                    safetyInfo: safetyInfoDict[name]
                )
            }
        } catch {
            Logger.error("Batch safety check failed", error: error, category: .echa)
            throw IngredientServiceError.networkError(error)
        }
    }

    func searchIngredient(query: String) async throws -> [Ingredient] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        do {
            return try await repository.searchIngredients(query: query)
        } catch {
            Logger.error("Ingredient search failed for '\(query)'", error: error, category: .echa)
            throw IngredientServiceError.networkError(error)
        }
    }

    func getIngredientDetails(identifier: String) async throws -> Ingredient? {
        do {
            return try await repository.fetchIngredient(identifier: identifier)
        } catch {
            Logger.error("Failed to fetch ingredient details for '\(identifier)'", error: error, category: .echa)
            throw IngredientServiceError.networkError(error)
        }
    }
}
