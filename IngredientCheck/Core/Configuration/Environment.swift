//
//  Environment.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Application environment configuration
enum Environment {
    case development
    case staging
    case production

    /// Current environment - change based on build configuration
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    /// Base URL for backend API (future use)
    var backendBaseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://localhost:3000")!
        case .staging:
            return URL(string: "https://staging-api.ingredientcheck.app")!
        case .production:
            return URL(string: "https://api.ingredientcheck.app")!
        }
    }

    /// Logging level
    var logLevel: LogLevel {
        switch self {
        case .development:
            return .debug
        case .staging:
            return .info
        case .production:
            return .warning
        }
    }

    /// Enable verbose logging
    var isVerboseLogging: Bool {
        self == .development
    }
}

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
