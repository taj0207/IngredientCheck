//
//  CameraScanViewModel.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for camera scanning screen
@MainActor
class CameraScanViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var scanResult: ScanResult?
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Dependencies

    private let ocrService: OCRServiceProtocol
    private let ingredientService: IngredientServiceProtocol
    private let userRepository: UserRepositoryProtocol

    // MARK: - Initialization

    init(
        ocrService: OCRServiceProtocol,
        ingredientService: IngredientServiceProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.ocrService = ocrService
        self.ingredientService = ingredientService
        self.userRepository = userRepository
    }

    // MARK: - Public Methods

    /// Process an image and extract ingredients
    func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        showError = false

        let startTime = Date()

        do {
            // Step 1: Extract ingredients using OCR
            Logger.info("Starting OCR extraction", category: .ocr)
            let ingredientNames = try await ocrService.extractIngredients(from: image)

            guard !ingredientNames.isEmpty else {
                throw OCRError.noTextDetected
            }

            Logger.info("Extracted \(ingredientNames.count) ingredients", category: .ocr)

            // Step 2: Check safety for each ingredient
            Logger.info("Checking safety for ingredients", category: .echa)
            let ingredients = try await ingredientService.checkSafety(for: ingredientNames)

            // Step 3: Create scan result
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ScanResult(
                ingredients: ingredients,
                processingTime: processingTime
            )

            // Step 4: Save to history
            if let user = try? await userRepository.getCurrentUser() {
                try? await userRepository.saveScanResult(result, for: user.id)
            }

            // Update UI
            scanResult = result
            isProcessing = false

            Logger.info("Scan completed successfully in \(String(format: "%.2f", processingTime))s", category: .general)

            // Post notification
            NotificationCenter.default.post(
                name: Constants.Notifications.scanDidComplete,
                object: result
            )

        } catch let error as OCRError {
            handleError(error)
        } catch let error as IngredientServiceError {
            handleError(error)
        } catch {
            handleError(error)
        }
    }

    /// Clear current results
    func clearResults() {
        scanResult = nil
        errorMessage = nil
        showError = false
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        isProcessing = false
        errorMessage = error.localizedDescription
        showError = true

        Logger.error("Scan failed", error: error, category: .general)
    }
}
