//
//  UserRepositoryImpl.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Implementation of user repository using UserDefaults
/// For production, consider using Keychain for sensitive data
class UserRepositoryImpl: UserRepositoryProtocol {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // Keys
    private let currentUserKey = "currentUser"
    private let scanHistoryPrefix = "scanHistory_"

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - UserRepositoryProtocol

    func getCurrentUser() async throws -> User? {
        guard let data = userDefaults.data(forKey: currentUserKey) else {
            return nil
        }

        do {
            return try decoder.decode(User.self, from: data)
        } catch {
            Logger.error("Failed to decode user", error: error, category: .data)
            throw RepositoryError.invalidData("Failed to decode user")
        }
    }

    func saveUser(_ user: User) async throws {
        do {
            let data = try encoder.encode(user)
            userDefaults.set(data, forKey: currentUserKey)
            Logger.info("User saved: \(user.id)", category: .data)
        } catch {
            Logger.error("Failed to save user", error: error, category: .data)
            throw RepositoryError.databaseError(error)
        }
    }

    func deleteUser(userId: String) async throws {
        userDefaults.removeObject(forKey: currentUserKey)
        // Also delete scan history
        userDefaults.removeObject(forKey: scanHistoryKey(for: userId))
        Logger.info("User deleted: \(userId)", category: .data)
    }

    func updateUser(_ user: User) async throws {
        try await saveUser(user)
    }

    func getScanHistory(for userId: String) async throws -> [ScanResult] {
        let key = scanHistoryKey(for: userId)
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            return try decoder.decode([ScanResult].self, from: data)
        } catch {
            Logger.error("Failed to decode scan history", error: error, category: .data)
            throw RepositoryError.invalidData("Failed to decode scan history")
        }
    }

    func saveScanResult(_ scanResult: ScanResult, for userId: String) async throws {
        var history = try await getScanHistory(for: userId)
        history.insert(scanResult, at: 0) // Add to beginning

        // Limit history to 100 items
        if history.count > 100 {
            history = Array(history.prefix(100))
        }

        do {
            let data = try encoder.encode(history)
            let key = scanHistoryKey(for: userId)
            userDefaults.set(data, forKey: key)
            Logger.info("Scan result saved for user: \(userId)", category: .data)
        } catch {
            Logger.error("Failed to save scan result", error: error, category: .data)
            throw RepositoryError.databaseError(error)
        }
    }

    func deleteScanResult(scanId: UUID, for userId: String) async throws {
        var history = try await getScanHistory(for: userId)
        history.removeAll { $0.id == scanId }

        do {
            let data = try encoder.encode(history)
            let key = scanHistoryKey(for: userId)
            userDefaults.set(data, forKey: key)
            Logger.info("Scan result deleted: \(scanId)", category: .data)
        } catch {
            Logger.error("Failed to delete scan result", error: error, category: .data)
            throw RepositoryError.databaseError(error)
        }
    }

    func clearAllData() async throws {
        if let userId = try await getCurrentUser()?.id {
            userDefaults.removeObject(forKey: scanHistoryKey(for: userId))
        }
        userDefaults.removeObject(forKey: currentUserKey)
        Logger.info("All user data cleared", category: .data)
    }

    // MARK: - Private Helpers

    private func scanHistoryKey(for userId: String) -> String {
        return "\(scanHistoryPrefix)\(userId)"
    }
}
