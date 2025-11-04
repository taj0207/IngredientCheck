//
//  DIContainer.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Dependency Injection Container
/// Centralized location for creating and managing dependencies
class DIContainer {

    // MARK: - Singleton

    static let shared = DIContainer()

    private init() {
        Logger.info("DIContainer initialized", category: .general)
    }

    // MARK: - Repositories

    /// Ingredient repository (data access layer)
    lazy var ingredientRepository: IngredientRepositoryProtocol = {
        if FeatureFlags.useBackend {
            // Future: Return backend repository implementation
            Logger.info("Using backend ingredient repository", category: .data)
            return IngredientRepositoryImpl() // Placeholder
        } else {
            Logger.info("Using direct ECHA ingredient repository", category: .data)
            return IngredientRepositoryImpl()
        }
    }()

    /// User repository
    lazy var userRepository: UserRepositoryProtocol = {
        UserRepositoryImpl()
    }()

    // MARK: - Services

    /// OCR service for ingredient extraction
    lazy var ocrService: OCRServiceProtocol = {
        OCRServiceImpl()
    }()

    /// Ingredient safety checking service
    lazy var ingredientService: IngredientServiceProtocol = {
        IngredientServiceImpl(repository: ingredientRepository)
    }()

    /// Authentication service
    lazy var authenticationService: AuthenticationServiceProtocol = {
        AuthenticationServiceImpl(userRepository: userRepository)
    }()

    // MARK: - API Clients

    /// Network client
    lazy var networkClient: NetworkClient = {
        NetworkClient()
    }()

    /// ECHA API client
    lazy var echaAPIClient: ECHAAPIClient = {
        ECHAAPIClient(networkClient: networkClient)
    }()

    /// LLM OCR client
    lazy var llmOCRClient: LLMOCRClient = {
        LLMOCRClient(
            networkClient: networkClient,
            model: FeatureFlags.primaryOCRProvider.modelName
        )
    }()

    // MARK: - Helper Methods

    /// Reset all dependencies (useful for testing)
    func reset() {
        // This will force recreation of all lazy properties next time they're accessed
        Logger.warning("DIContainer reset - all services will be recreated", category: .general)
    }
}

// MARK: - SwiftUI Environment Key

import SwiftUI

/// Environment key for dependency injection
struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = DIContainer.shared
}

extension EnvironmentValues {
    var container: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject dependencies into the environment
    func withDependencies(_ container: DIContainer = .shared) -> some View {
        environment(\.container, container)
    }
}
