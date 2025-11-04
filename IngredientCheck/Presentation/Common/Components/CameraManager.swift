//
//  CameraManager.swift
//  IngredientCheck
//
//  Created on 2025-11-03
//

import SwiftUI
import UIKit
import AVFoundation

/// Camera manager for capturing photos
class CameraManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var capturedImage: UIImage?
    @Published var showCamera = false
    @Published var cameraError: CameraError?
    @Published var showError = false

    // MARK: - Public Methods

    /// Check if camera is available
    func isCameraAvailable() -> Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Check camera permission status
    func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return true

        case .notDetermined:
            // Request permission
            return await AVCaptureDevice.requestAccess(for: .video)

        case .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }

    /// Request camera permission and show camera if granted
    func requestCameraAndShow() async {
        guard isCameraAvailable() else {
            cameraError = .notAvailable
            showError = true
            return
        }

        let hasPermission = await checkCameraPermission()

        await MainActor.run {
            if hasPermission {
                showCamera = true
            } else {
                cameraError = .permissionDenied
                showError = true
            }
        }
    }

    /// Handle captured image
    func handleCapturedImage(_ image: UIImage?) {
        capturedImage = image
        showCamera = false
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case notAvailable
    case permissionDenied
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return NSLocalizedString("camera.error.not_available", comment: "Camera is not available on this device")
        case .permissionDenied:
            return NSLocalizedString("camera.error.permission_denied", comment: "Camera permission was denied. Please enable it in Settings.")
        case .captureFailed:
            return NSLocalizedString("camera.error.capture_failed", comment: "Failed to capture photo. Please try again.")
        }
    }
}
