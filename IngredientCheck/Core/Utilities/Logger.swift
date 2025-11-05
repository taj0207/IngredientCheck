//
//  Logger.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import os.log

/// Centralized logging utility
struct Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.ingredientcheck.app"

    // MARK: - Log Categories

    private static let networkLog = OSLog(subsystem: subsystem, category: "Network")
    private static let ocrLog = OSLog(subsystem: subsystem, category: "OCR")
    private static let echaLog = OSLog(subsystem: subsystem, category: "ECHA")
    private static let authLog = OSLog(subsystem: subsystem, category: "Auth")
    private static let uiLog = OSLog(subsystem: subsystem, category: "UI")
    private static let dataLog = OSLog(subsystem: subsystem, category: "Data")
    private static let generalLog = OSLog(subsystem: subsystem, category: "General")

    // MARK: - Log Levels

    /// Debug level logging
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppEnvironment.current.logLevel <= .debug else { return }
        let log = category.osLog
        let fileName = (file as NSString).lastPathComponent
        os_log(.debug, log: log, "%{public}@ [%{public}@:%d] %{public}@", fileName, function, line, message)
    }

    /// Info level logging
    static func info(_ message: String, category: Category = .general) {
        guard AppEnvironment.current.logLevel <= .info else { return }
        let log = category.osLog
        os_log(.info, log: log, "%{public}@", message)
    }

    /// Warning level logging
    static func warning(_ message: String, category: Category = .general) {
        guard AppEnvironment.current.logLevel <= .warning else { return }
        let log = category.osLog
        os_log(.default, log: log, "⚠️ %{public}@", message)
    }

    /// Error level logging
    static func error(_ message: String, error: Error? = nil, category: Category = .general) {
        let log = category.osLog
        if let error = error {
            os_log(.error, log: log, "❌ %{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: log, "❌ %{public}@", message)
        }
    }

    // MARK: - Specialized Logging

    /// Log network request
    static func logNetworkRequest(url: String, method: String = "GET") {
        debug("[\(method)] \(url)", category: .network)
    }

    /// Log network response
    static func logNetworkResponse(url: String, statusCode: Int, duration: TimeInterval) {
        if statusCode >= 200 && statusCode < 300 {
            info("✓ [\(statusCode)] \(url) - \(String(format: "%.2f", duration))s", category: .network)
        } else {
            warning("✗ [\(statusCode)] \(url) - \(String(format: "%.2f", duration))s", category: .network)
        }
    }

    /// Log OCR extraction
    static func logOCRExtraction(ingredientCount: Int, duration: TimeInterval, provider: OCRProvider) {
        info("OCR extracted \(ingredientCount) ingredients using \(provider.displayName) in \(String(format: "%.2f", duration))s", category: .ocr)
    }

    /// Log ECHA API call
    static func logECHAQuery(ingredient: String, found: Bool) {
        if found {
            info("ECHA: Found safety info for '\(ingredient)'", category: .echa)
        } else {
            warning("ECHA: No data found for '\(ingredient)'", category: .echa)
        }
    }

    // MARK: - Category Enum

    enum Category {
        case network
        case ocr
        case echa
        case auth
        case ui
        case data
        case general

        var osLog: OSLog {
            switch self {
            case .network: return networkLog
            case .ocr: return ocrLog
            case .echa: return echaLog
            case .auth: return authLog
            case .ui: return uiLog
            case .data: return dataLog
            case .general: return generalLog
            }
        }
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log view lifecycle
    static func viewDidAppear(_ viewName: String) {
        debug("\(viewName) appeared", category: .ui)
    }

    static func viewDidDisappear(_ viewName: String) {
        debug("\(viewName) disappeared", category: .ui)
    }
}
