//
//  AuthenticationServiceImpl.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import AuthenticationServices

/// Implementation of authentication service
class AuthenticationServiceImpl: NSObject, AuthenticationServiceProtocol {

    // MARK: - Properties

    private let userRepository: UserRepositoryProtocol
    private var currentAuthUser: User?

    // MARK: - Initialization

    init(userRepository: UserRepositoryProtocol = UserRepositoryImpl()) {
        self.userRepository = userRepository
        super.init()
    }

    // MARK: - AuthenticationServiceProtocol

    var currentUser: User? {
        get async {
            if let user = currentAuthUser {
                return user
            }
            // Load from repository
            currentAuthUser = try? await userRepository.getCurrentUser()
            return currentAuthUser
        }
    }

    var isAuthenticated: Bool {
        get async {
            await currentUser != nil
        }
    }

    func signInWithApple() async throws -> User {
        guard FeatureFlags.enableAppleSignIn else {
            throw AuthenticationError.unknownError(
                NSError(domain: "AuthenticationService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Sign in with Apple is not enabled"
                ])
            )
        }

        // Note: This is a placeholder. Actual implementation would use ASAuthorizationController
        // For now, create a mock user for development
        Logger.info("Sign in with Apple requested", category: .auth)

        // TODO: Implement actual Apple Sign In flow
        // This requires ASAuthorizationAppleIDProvider and proper UI integration

        throw AuthenticationError.unknownError(
            NSError(domain: "AuthenticationService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Apple Sign In not yet implemented. Use anonymous sign in for now."
            ])
        )
    }

    func signInWithGoogle() async throws -> User {
        guard FeatureFlags.enableGoogleSignIn else {
            throw AuthenticationError.unknownError(
                NSError(domain: "AuthenticationService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Sign in with Google is not enabled"
                ])
            )
        }

        Logger.info("Sign in with Google requested", category: .auth)

        // TODO: Implement Google Sign In
        // This requires GoogleSignIn SDK integration

        throw AuthenticationError.unknownError(
            NSError(domain: "AuthenticationService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Google Sign In not yet implemented. Use anonymous sign in for now."
            ])
        )
    }

    func signInAnonymously() async throws -> User {
        Logger.info("Anonymous sign in", category: .auth)

        let user = User(
            id: UUID().uuidString,
            email: nil,
            displayName: "Guest User",
            photoURL: nil,
            authProvider: .anonymous
        )

        try await userRepository.saveUser(user)
        currentAuthUser = user

        NotificationCenter.default.post(name: Constants.Notifications.userDidLogin, object: user)

        return user
    }

    func signOut() async throws {
        guard await isAuthenticated else {
            throw AuthenticationError.notAuthenticated
        }

        if let userId = currentAuthUser?.id {
            try await userRepository.deleteUser(userId: userId)
        }

        currentAuthUser = nil
        Logger.info("User signed out", category: .auth)

        NotificationCenter.default.post(name: Constants.Notifications.userDidLogout, object: nil)
    }

    func deleteAccount() async throws {
        guard await isAuthenticated else {
            throw AuthenticationError.notAuthenticated
        }

        try await userRepository.clearAllData()
        currentAuthUser = nil

        Logger.info("User account deleted", category: .auth)
    }

    func refreshToken() async throws -> String {
        // TODO: Implement token refresh when backend is ready
        throw AuthenticationError.unknownError(
            NSError(domain: "AuthenticationService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Token refresh not yet implemented"
            ])
        )
    }
}
