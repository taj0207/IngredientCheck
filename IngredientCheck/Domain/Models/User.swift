//
//  User.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// User model for authentication and profile
struct User: Identifiable, Codable {

    // MARK: - Properties

    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let authProvider: AuthProvider
    let createdAt: Date
    let lastLoginAt: Date

    // MARK: - Initialization

    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: URL? = nil,
        authProvider: AuthProvider,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }

    // MARK: - Computed Properties

    var displayNameOrEmail: String {
        displayName ?? email ?? "User"
    }

    var initials: String {
        if let displayName = displayName {
            let components = displayName.components(separatedBy: " ")
            let initials = components.compactMap { $0.first }.prefix(2)
            return String(initials).uppercased()
        } else if let email = email {
            return String(email.prefix(2)).uppercased()
        } else {
            return "U"
        }
    }
}

// MARK: - Auth Provider

enum AuthProvider: String, Codable {
    case apple = "apple"
    case google = "google"
    case email = "email"
    case anonymous = "anonymous"

    var displayName: String {
        switch self {
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .email:
            return "Email"
        case .anonymous:
            return "Guest"
        }
    }
}

// MARK: - Sample Data

extension User {
    static let sample = User(
        id: "sample-user-123",
        email: "user@example.com",
        displayName: "Sample User",
        photoURL: nil,
        authProvider: .apple
    )

    static let sampleAnonymous = User(
        id: "anonymous-user",
        email: nil,
        displayName: "Guest User",
        photoURL: nil,
        authProvider: .anonymous
    )
}
