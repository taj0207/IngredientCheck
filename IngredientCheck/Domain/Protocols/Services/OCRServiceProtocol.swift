//
//  OCRServiceProtocol.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import UIKit

/// Protocol for OCR (Optical Character Recognition) service
/// Extracts ingredient lists from product label images
protocol OCRServiceProtocol {

    /// Extract ingredients from an image
    /// - Parameters:
    ///   - image: The image containing ingredient list
    ///   - language: Preferred language for extraction (optional)
    /// - Returns: Array of extracted ingredient names
    /// - Throws: OCRError if extraction fails
    func extractIngredients(
        from image: UIImage,
        language: String?
    ) async throws -> [String]

    /// Extract ingredients with additional metadata
    /// - Parameters:
    ///   - image: The image containing ingredient list
    ///   - language: Preferred language for extraction (optional)
    /// - Returns: OCR result with ingredients and metadata
    /// - Throws: OCRError if extraction fails
    func extractIngredientsDetailed(
        from image: UIImage,
        language: String?
    ) async throws -> OCRResult
}

// MARK: - Default Parameters

extension OCRServiceProtocol {
    func extractIngredients(from image: UIImage) async throws -> [String] {
        try await extractIngredients(from: image, language: nil)
    }

    func extractIngredientsDetailed(from image: UIImage) async throws -> OCRResult {
        try await extractIngredientsDetailed(from: image, language: nil)
    }
}

// MARK: - OCR Result

/// Detailed result from OCR extraction
struct OCRResult {
    let ingredients: [String]
    let productName: String?
    let brand: String?
    let confidence: Double // 0.0 - 1.0
    let processingTime: TimeInterval
    let provider: String
}

// MARK: - OCR Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextDetected
    case apiKeyMissing
    case rateLimitExceeded
    case networkError(Error)
    case parsingError(String)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return NSLocalizedString("ocr.error.invalid_image", comment: "Invalid or corrupted image")
        case .noTextDetected:
            return NSLocalizedString("ocr.error.no_text", comment: "No text detected in image. Please try a clearer photo.")
        case .apiKeyMissing:
            return NSLocalizedString("ocr.error.api_key", comment: "API key is missing or invalid")
        case .rateLimitExceeded:
            return NSLocalizedString("ocr.error.rate_limit", comment: "Too many requests. Please try again later.")
        case .networkError(let error):
            return String(format: NSLocalizedString("ocr.error.network", comment: "Network error: %@"), error.localizedDescription)
        case .parsingError(let message):
            return String(format: NSLocalizedString("ocr.error.parsing", comment: "Failed to parse response: %@"), message)
        case .unknownError(let error):
            return error.localizedDescription
        }
    }
}
