//
//  APIConfig.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// API configuration for external services
struct APIConfig {

    // MARK: - OpenAI Configuration

    /// OpenAI API base URL
    static let openAIBaseURL = "https://api.openai.com/v1"

    /// GPT-5-mini model identifier
    static let gpt5MiniModel = "gpt-5-mini"

    /// GPT-5 model identifier (fallback)
    static let gpt5Model = "gpt-5"

    /// Maximum tokens for OCR response
    static let maxOCRTokens = 1024

    /// Timeout for OCR requests (seconds)
    static let ocrTimeout: TimeInterval = 30

    /// OpenAI API key (loaded from Secrets.swift)
    static var openAIAPIKey: String {
        #if DEBUG
        // In development, try to load from Secrets.swift
        return Secrets.openAIAPIKey
        #else
        // In production, load from environment or keychain
        return Secrets.openAIAPIKey
        #endif
    }

    // MARK: - ECHA Configuration

    /// ECHA API base URL
    static let echaBaseURL = "https://echa.europa.eu/api"

    /// ECHA dissemination API
    static let echaDisseminationURL = "https://echa.europa.eu/api/diss"

    /// ECHA timeout (seconds)
    static let echaTimeout: TimeInterval = 15

    // MARK: - Cache Configuration

    /// Cache duration for ECHA results (24 hours)
    static let echaCacheDuration: TimeInterval = 24 * 60 * 60

    /// Maximum cache size (MB)
    static let maxCacheSizeMB = 50

    // MARK: - OAuth Configuration

    /// Google OAuth Client ID (optional)
    static var googleOAuthClientID: String? {
        Secrets.googleOAuthClientID
    }

    /// OAuth redirect URI
    static let oauthRedirectURI = "com.ingredientcheck.app://oauth-callback"

    // MARK: - Rate Limiting

    /// Maximum concurrent API requests
    static let maxConcurrentRequests = 3

    /// Retry attempts for failed requests
    static let maxRetryAttempts = 2

    /// Delay between retries (seconds)
    static let retryDelay: TimeInterval = 1.0
}

/// Placeholder for secrets - this file should be git-ignored
/// Create this file manually: IngredientCheck/Core/Configuration/Secrets.swift
enum Secrets {
    static let openAIAPIKey = "sk-proj-YOUR_API_KEY_HERE"
    static let googleOAuthClientID: String? = nil
}
