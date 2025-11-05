//
//  Constants.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import SwiftUI

/// Application-wide constants
enum Constants {

    // MARK: - App Information

    static let appName = "IngredientCheck"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Image Processing

    /// Maximum image size for OCR (pixels)
    static let maxImageDimension: CGFloat = 2048

    /// JPEG compression quality (0.0 - 1.0)
    static let imageCompressionQuality: CGFloat = 0.8

    /// Maximum image file size (MB)
    static let maxImageSizeMB = 5

    // MARK: - UI Constants

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let buttonHeight: CGFloat = 50
        static let spacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24

        /// Animation duration
        static let animationDuration: TimeInterval = 0.3

        /// Debounce delay for search
        static let searchDebounceDelay: TimeInterval = 0.5
    }

    // MARK: - Safety Levels

    enum SafetyLevel: String, CaseIterable, Codable {
        case safe = "safe"
        case caution = "caution"
        case warning = "warning"
        case danger = "danger"
        case unknown = "unknown"

        var color: Color {
            switch self {
            case .safe: return .green
            case .caution: return .yellow
            case .warning: return .orange
            case .danger: return .red
            case .unknown: return .gray
            }
        }

        var icon: String {
            switch self {
            case .safe: return "checkmark.circle.fill"
            case .caution: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .danger: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }

        var localizedTitle: String {
            switch self {
            case .safe: return NSLocalizedString("safety.level.safe", comment: "Safe")
            case .caution: return NSLocalizedString("safety.level.caution", comment: "Caution")
            case .warning: return NSLocalizedString("safety.level.warning", comment: "Warning")
            case .danger: return NSLocalizedString("safety.level.danger", comment: "Danger")
            case .unknown: return NSLocalizedString("safety.level.unknown", comment: "Unknown")
            }
        }
    }

    // MARK: - User Defaults Keys

    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredLanguage = "preferredLanguage"
        static let enableHapticFeedback = "enableHapticFeedback"
        static let scanHistory = "scanHistory"
        static let lastSyncDate = "lastSyncDate"
    }

    // MARK: - Notification Names

    enum Notifications {
        static let userDidLogin = Notification.Name("userDidLogin")
        static let userDidLogout = Notification.Name("userDidLogout")
        static let scanDidComplete = Notification.Name("scanDidComplete")
        static let cacheDidClear = Notification.Name("cacheDidClear")
    }

    // MARK: - Error Messages

    enum ErrorMessages {
        static let genericError = NSLocalizedString("error.generic", comment: "Something went wrong. Please try again.")
        static let networkError = NSLocalizedString("error.network", comment: "Network connection error. Please check your internet connection.")
        static let ocrError = NSLocalizedString("error.ocr", comment: "Failed to extract ingredients from image. Please try again with a clearer photo.")
        static let echaError = NSLocalizedString("error.echa", comment: "Failed to fetch safety information. Please try again later.")
        static let cameraPermissionError = NSLocalizedString("error.camera.permission", comment: "Camera permission is required to scan ingredients.")
        static let photoLibraryPermissionError = NSLocalizedString("error.photo.permission", comment: "Photo library access is required to select images.")
    }
}
