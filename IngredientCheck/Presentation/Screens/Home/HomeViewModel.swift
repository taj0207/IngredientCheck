//
//  HomeViewModel.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import Combine

/// ViewModel for home screen
@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var user: User?
    @Published var scanHistory: [ScanResult] = []
    @Published var isLoading = false

    // MARK: - Dependencies

    private let authService: AuthenticationServiceProtocol
    private let userRepository: UserRepositoryProtocol

    // MARK: - Initialization

    init(
        authService: AuthenticationServiceProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.authService = authService
        self.userRepository = userRepository

        // Don't call async methods in init - it causes crashes
        // Let the view call loadUser() in .onAppear instead
    }

    // MARK: - Public Methods

    /// Load current user
    func loadUser() async {
        user = await authService.currentUser

        if let userId = user?.id {
            await loadScanHistory(for: userId)
        }
    }

    /// Load scan history
    func loadScanHistory(for userId: String) async {
        isLoading = true

        do {
            scanHistory = try await userRepository.getScanHistory(for: userId)
        } catch {
            Logger.error("Failed to load scan history", error: error, category: .data)
        }

        isLoading = false
    }

    /// Sign in anonymously
    func signInAnonymously() async {
        do {
            user = try await authService.signInAnonymously()
            Logger.info("Signed in anonymously", category: .auth)
        } catch {
            Logger.error("Anonymous sign in failed", error: error, category: .auth)
        }
    }

    /// Sign out
    func signOut() async {
        do {
            try await authService.signOut()
            user = nil
            scanHistory = []
            Logger.info("Signed out", category: .auth)
        } catch {
            Logger.error("Sign out failed", error: error, category: .auth)
        }
    }

    /// Delete scan from history
    func deleteScan(_ scanResult: ScanResult) async {
        guard let userId = user?.id else { return }

        do {
            try await userRepository.deleteScanResult(scanId: scanResult.id, for: userId)
            await loadScanHistory(for: userId)
        } catch {
            Logger.error("Failed to delete scan", error: error, category: .data)
        }
    }
}
