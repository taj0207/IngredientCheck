//
//  IngredientRepositoryImpl.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Implementation of ingredient repository
/// Currently uses ECHA API directly, can be easily switched to backend API
class IngredientRepositoryImpl: IngredientRepositoryProtocol {

    // MARK: - Properties

    private let echaClient: ECHAAPIClient
    private let cacheManager: CacheManager

    // MARK: - Initialization

    init(
        echaClient: ECHAAPIClient = ECHAAPIClient(),
        cacheManager: CacheManager = CacheManager.shared
    ) {
        self.echaClient = echaClient
        self.cacheManager = cacheManager
    }

    // MARK: - IngredientRepositoryProtocol

    func fetchSafetyInfo(for identifier: String) async throws -> SafetyInfo? {
        // Check cache first if enabled
        if FeatureFlags.enableLocalCache {
            if let cached = await cacheManager.getSafetyInfo(for: identifier) {
                Logger.debug("Cache hit for '\(identifier)'", category: .data)
                return cached
            }
        }

        // Fetch from ECHA
        do {
            let safetyInfo = try await echaClient.fetchSafetyInfo(for: identifier)

            // Cache the result
            if let safetyInfo = safetyInfo, FeatureFlags.enableLocalCache {
                await cacheManager.setSafetyInfo(safetyInfo, for: identifier)
            }

            return safetyInfo
        } catch let error as NetworkError {
            throw RepositoryError.networkError(error)
        } catch {
            throw RepositoryError.unknownError(error)
        }
    }

    func fetchSafetyInfo(for identifiers: [String]) async throws -> [String: SafetyInfo] {
        var results: [String: SafetyInfo] = [:]

        // Fetch concurrently with limit
        await withTaskGroup(of: (String, SafetyInfo?).self) { group in
            for identifier in identifiers {
                group.addTask {
                    let info = try? await self.fetchSafetyInfo(for: identifier)
                    return (identifier, info)
                }
            }

            for await (identifier, info) in group {
                if let info = info {
                    results[identifier] = info
                }
            }
        }

        return results
    }

    func searchIngredients(query: String) async throws -> [Ingredient] {
        do {
            let substances = try await echaClient.searchSubstance(query: query)

            return substances.map { substance in
                Ingredient(
                    name: substance.name,
                    casNumber: substance.casNumber,
                    ecNumber: substance.ecNumber
                )
            }
        } catch let error as NetworkError {
            throw RepositoryError.networkError(error)
        } catch {
            throw RepositoryError.unknownError(error)
        }
    }

    func fetchIngredient(identifier: String) async throws -> Ingredient? {
        // Search for the ingredient
        let results = try await searchIngredients(query: identifier)
        guard let result = results.first else {
            return nil
        }

        // Fetch safety info
        let safetyInfo = try await fetchSafetyInfo(for: identifier)

        return Ingredient(
            name: result.name,
            casNumber: result.casNumber,
            ecNumber: result.ecNumber,
            safetyInfo: safetyInfo
        )
    }

    func clearCache() async throws {
        do {
            await cacheManager.clearSafetyInfoCache()
            Logger.info("Cache cleared successfully", category: .data)
        } catch {
            throw RepositoryError.cacheError(error)
        }
    }
}

// MARK: - Cache Manager

/// Simple in-memory cache manager
/// In production, this could use CoreData or a persistent cache
actor CacheManager {

    static let shared = CacheManager()

    private var safetyInfoCache: [String: CachedSafetyInfo] = [:]

    private struct CachedSafetyInfo {
        let info: SafetyInfo
        let timestamp: Date
    }

    func getSafetyInfo(for identifier: String) -> SafetyInfo? {
        guard let cached = safetyInfoCache[identifier] else {
            return nil
        }

        // Check if cache is still valid
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > FeatureFlags.cacheDuration {
            safetyInfoCache.removeValue(forKey: identifier)
            return nil
        }

        return cached.info
    }

    func setSafetyInfo(_ info: SafetyInfo, for identifier: String) {
        safetyInfoCache[identifier] = CachedSafetyInfo(
            info: info,
            timestamp: Date()
        )
    }

    func clearSafetyInfoCache() {
        safetyInfoCache.removeAll()
    }
}
