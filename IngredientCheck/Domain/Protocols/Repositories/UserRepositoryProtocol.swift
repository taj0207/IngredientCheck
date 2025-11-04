//
//  UserRepositoryProtocol.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Repository protocol for user data access
protocol UserRepositoryProtocol {

    /// Get current user from local storage
    /// - Returns: Current user if exists
    func getCurrentUser() async throws -> User?

    /// Save user to local storage
    /// - Parameter user: User to save
    func saveUser(_ user: User) async throws

    /// Delete user from local storage
    /// - Parameter userId: ID of user to delete
    func deleteUser(userId: String) async throws

    /// Update user information
    /// - Parameter user: Updated user object
    func updateUser(_ user: User) async throws

    /// Get scan history for user
    /// - Parameter userId: User ID
    /// - Returns: Array of scan results
    func getScanHistory(for userId: String) async throws -> [ScanResult]

    /// Save scan result
    /// - Parameters:
    ///   - scanResult: Scan result to save
    ///   - userId: User ID
    func saveScanResult(_ scanResult: ScanResult, for userId: String) async throws

    /// Delete scan result
    /// - Parameters:
    ///   - scanId: Scan result ID
    ///   - userId: User ID
    func deleteScanResult(scanId: UUID, for userId: String) async throws

    /// Clear all user data
    func clearAllData() async throws
}
