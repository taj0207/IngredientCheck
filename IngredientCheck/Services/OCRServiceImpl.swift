//
//  OCRServiceImpl.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import UIKit

/// Implementation of OCR service using LLM vision models
class OCRServiceImpl: OCRServiceProtocol {

    // MARK: - Properties

    private let primaryClient: LLMOCRClient
    private let fallbackClient: LLMOCRClient?

    // MARK: - Initialization

    init(
        primaryClient: LLMOCRClient? = nil,
        fallbackClient: LLMOCRClient? = nil
    ) {
        // Initialize primary client
        let primaryProvider = FeatureFlags.primaryOCRProvider
        self.primaryClient = primaryClient ?? LLMOCRClient(
            model: primaryProvider.modelName
        )

        // Initialize fallback client if enabled
        if FeatureFlags.enableOCRFallback,
           let fallbackProvider = FeatureFlags.fallbackOCRProvider {
            self.fallbackClient = fallbackClient ?? LLMOCRClient(
                model: fallbackProvider.modelName
            )
        } else {
            self.fallbackClient = nil
        }
    }

    // MARK: - OCRServiceProtocol

    func extractIngredients(
        from image: UIImage,
        language: String? = nil
    ) async throws -> [String] {
        do {
            // Try primary client
            Logger.info("Attempting OCR with primary provider: \(FeatureFlags.primaryOCRProvider.displayName)", category: .ocr)
            let ingredients = try await primaryClient.extractIngredients(
                from: image,
                language: language
            )

            guard !ingredients.isEmpty else {
                throw OCRError.noTextDetected
            }

            return ingredients
        } catch {
            // Try fallback if available
            if let fallbackClient = fallbackClient {
                Logger.warning("Primary OCR failed, trying fallback provider", category: .ocr)
                return try await fallbackClient.extractIngredients(
                    from: image,
                    language: language
                )
            } else {
                throw error
            }
        }
    }

    func extractIngredientsDetailed(
        from image: UIImage,
        language: String? = nil
    ) async throws -> OCRResult {
        do {
            // Try primary client
            return try await primaryClient.extractIngredientsDetailed(
                from: image,
                language: language
            )
        } catch {
            // Try fallback if available
            if let fallbackClient = fallbackClient {
                Logger.warning("Primary OCR failed, trying fallback provider", category: .ocr)
                return try await fallbackClient.extractIngredientsDetailed(
                    from: image,
                    language: language
                )
            } else {
                throw error
            }
        }
    }
}
