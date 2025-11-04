//
//  AuthenticationServiceProtocol.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Protocol for authentication service
protocol AuthenticationServiceProtocol {

    /// Current authenticated user
    var currentUser: User? { get async }

    /// Check if user is authenticated
    var isAuthenticated: Bool { get async }

    /// Sign in with Apple
    /// - Returns: Authenticated user
    /// - Throws: AuthenticationError if sign in fails
    func signInWithApple() async throws -> User

    /// Sign in with Google
    /// - Returns: Authenticated user
    /// - Throws: AuthenticationError if sign in fails
    func signInWithGoogle() async throws -> User

    /// Sign in anonymously (guest mode)
    /// - Returns: Anonymous user
    /// - Throws: AuthenticationError if sign in fails
    func signInAnonymously() async throws -> User

    /// Sign out current user
    /// - Throws: AuthenticationError if sign out fails
    func signOut() async throws

    /// Delete user account
    /// - Throws: AuthenticationError if deletion fails
    func deleteAccount() async throws

    /// Refresh authentication token
    /// - Returns: New token string
    /// - Throws: AuthenticationError if refresh fails
    func refreshToken() async throws -> String
}

// MARK: - Authentication Errors

enum AuthenticationError: LocalizedError {
    case notAuthenticated
    case cancelled
    case invalidCredentials
    case accountDisabled
    case networkError(Error)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return NSLocalizedString("auth.error.not_authenticated", comment: "User is not authenticated")
        case .cancelled:
            return NSLocalizedString("auth.error.cancelled", comment: "Sign in was cancelled")
        case .invalidCredentials:
            return NSLocalizedString("auth.error.invalid_credentials", comment: "Invalid credentials")
        case .accountDisabled:
            return NSLocalizedString("auth.error.account_disabled", comment: "Account has been disabled")
        case .networkError(let error):
            return String(format: NSLocalizedString("auth.error.network", comment: "Network error: %@"), error.localizedDescription)
        case .unknownError(let error):
            return error.localizedDescription
        }
    }
}
