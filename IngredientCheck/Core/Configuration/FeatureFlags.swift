//
//  FeatureFlags.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Feature flags for toggling functionality
struct FeatureFlags {

    // MARK: - Backend Integration

    /// Use backend API instead of direct ECHA calls
    /// When true, all data fetching goes through backend
    /// When false, app calls ECHA API directly
    static var useBackend = false

    // MARK: - OCR Provider

    /// Primary OCR provider
    static var primaryOCRProvider: OCRProvider = .gpt5Mini

    /// Fallback OCR provider when primary fails
    static var fallbackOCRProvider: OCRProvider? = .gpt5

    /// Enable OCR fallback on failure
    static var enableOCRFallback = true

    // MARK: - Authentication

    /// Enable Sign in with Apple
    static var enableAppleSignIn = true

    /// Enable Google Sign In
    static var enableGoogleSignIn = false // TODO: Enable when configured

    /// Require authentication to use app
    static var requireAuthentication = false // Set to true when backend is ready

    // MARK: - Caching

    /// Enable local caching of ECHA results
    static var enableLocalCache = true

    /// Enable image caching
    static var enableImageCache = true

    /// Cache duration in seconds
    static var cacheDuration: TimeInterval = APIConfig.echaCacheDuration

    // MARK: - UI Features

    /// Enable scan history
    static var enableScanHistory = true

    /// Enable ingredient favorites
    static var enableFavorites = false // TODO: Implement

    /// Enable sharing scan results
    static var enableSharing = true

    /// Show detailed safety information
    static var showDetailedSafetyInfo = true

    // MARK: - Analytics

    /// Enable usage analytics
    static var enableAnalytics = false // TODO: Implement when backend ready

    /// Enable crash reporting
    static var enableCrashReporting = false // TODO: Implement

    // MARK: - Development

    /// Enable debug logging
    static var enableDebugLogging = Environment.current == .development

    /// Show API response time in UI
    static var showAPIResponseTime = Environment.current == .development

    /// Enable mock data for testing
    static var useMockData = false
}

/// OCR provider options
enum OCRProvider {
    case gpt5Mini
    case gpt5
    case claude

    var modelName: String {
        switch self {
        case .gpt5Mini:
            return APIConfig.gpt5MiniModel
        case .gpt5:
            return APIConfig.gpt5Model
        case .claude:
            return "claude-sonnet-4-5-20250929"
        }
    }

    var displayName: String {
        switch self {
        case .gpt5Mini:
            return "GPT-5 Mini"
        case .gpt5:
            return "GPT-5"
        case .claude:
            return "Claude Sonnet 4.5"
        }
    }
}
