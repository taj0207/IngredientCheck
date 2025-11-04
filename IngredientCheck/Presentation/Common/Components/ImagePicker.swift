//
//  ImagePicker.swift
//  IngredientCheck
//
//  Created on 2025-11-03
//

import SwiftUI
import UIKit

/// SwiftUI wrapper for UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {

    // MARK: - Properties

    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Coordinator

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // Get the captured/selected image
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                Logger.info("Image captured/selected successfully", category: .ui)
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Logger.info("Image picker cancelled", category: .ui)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - UIViewControllerRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType

        // Configure camera settings if using camera
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.showsCameraControls = true
            picker.allowsEditing = false
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
}

// MARK: - Camera Button with Permission Handling

struct CameraButton: View {
    @ObservedObject var cameraManager: CameraManager
    let action: (UIImage) -> Void

    var body: some View {
        Button(action: {
            Task {
                await cameraManager.requestCameraAndShow()
            }
        }) {
            Label("Take Photo", systemImage: "camera.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.UI.buttonHeight)
                .background(Color.green)
                .cornerRadius(Constants.UI.cornerRadius)
        }
        .fullScreenCover(isPresented: $cameraManager.showCamera) {
            ImagePicker(
                sourceType: .camera,
                selectedImage: $cameraManager.capturedImage
            )
        }
        .onChange(of: cameraManager.capturedImage) { newImage in
            if let image = newImage {
                action(image)
                cameraManager.capturedImage = nil // Reset for next use
            }
        }
        .alert("Camera Error", isPresented: $cameraManager.showError) {
            Button("OK", role: .cancel) { }
            if cameraManager.cameraError == .permissionDenied {
                Button("Open Settings") {
                    openSettings()
                }
            }
        } message: {
            if let error = cameraManager.cameraError {
                Text(error.errorDescription ?? "Unknown error")
            }
        }
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Preview

#Preview {
    CameraButton(cameraManager: CameraManager()) { image in
        print("Image captured: \(image.size)")
    }
}
