//
//  CameraScanView.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import SwiftUI
import PhotosUI

struct CameraScanView: View {
    @Environment(\.container) var container
    @StateObject private var viewModel: CameraScanViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false

    init() {
        _viewModel = StateObject(wrappedValue: CameraScanViewModel(
            ocrService: DIContainer.shared.ocrService,
            ingredientService: DIContainer.shared.ingredientService,
            userRepository: DIContainer.shared.userRepository
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isProcessing {
                    processingView
                } else if let result = viewModel.scanResult {
                    resultView(result)
                } else {
                    placeholderView
                }
            }
            .navigationTitle("Scan Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
                    viewModel.clearResults()
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error occurred")
            }
        }
    }

    // MARK: - Subviews

    private var placeholderView: some View {
        VStack(spacing: Constants.UI.largeSpacing) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Scan Ingredient List")
                .font(.title2)
                .fontWeight(.bold)

            Text("Take a photo or choose from library to check ingredient safety")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.UI.largeSpacing)

            Spacer()

            VStack(spacing: Constants.UI.spacing) {
                // Camera Button
                Button(action: {
                    // TODO: Implement camera capture
                    showCamera = true
                }) {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.UI.buttonHeight)
                        .background(Color.green)
                        .cornerRadius(Constants.UI.cornerRadius)
                }

                // Photo Library Button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.UI.buttonHeight)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(Constants.UI.cornerRadius)
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await viewModel.processImage(image)
                        }
                    }
                }
            }
            .padding(.horizontal, Constants.UI.largeSpacing)
            .padding(.bottom, Constants.UI.largeSpacing)
        }
        .alert("Camera Not Available", isPresented: $showCamera) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Camera capture will be available soon. Please use photo library for now.")
        }
    }

    private var processingView: some View {
        VStack(spacing: Constants.UI.largeSpacing) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing Ingredients...")
                .font(.headline)

            Text("This may take a few seconds")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func resultView(_ result: ScanResult) -> some View {
        ScrollView {
            VStack(spacing: Constants.UI.largeSpacing) {
                // Overall Result Card
                overallResultCard(result)

                // Ingredients List
                ingredientsListView(result)

                // Actions
                actionButtonsView
            }
            .padding()
        }
    }

    private func overallResultCard(_ result: ScanResult) -> some View {
        VStack(spacing: Constants.UI.spacing) {
            Image(systemName: result.overallSafetyLevel.icon)
                .font(.system(size: 60))
                .foregroundColor(result.overallSafetyLevel.color)

            Text(result.overallSafetyLevel.localizedTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(result.summary)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Label("\(result.ingredientCount) ingredients", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.2fs", result.processingTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, Constants.UI.smallSpacing)
        }
        .padding()
        .background(result.overallSafetyLevel.color.opacity(0.1))
        .cornerRadius(Constants.UI.cornerRadius)
    }

    private func ingredientsListView(_ result: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: Constants.UI.spacing) {
            Text("Ingredients")
                .font(.headline)

            ForEach(result.ingredients) { ingredient in
                IngredientResultCard(ingredient: ingredient)
            }
        }
    }

    private var actionButtonsView: some View {
        VStack(spacing: Constants.UI.spacing) {
            Button(action: {
                viewModel.clearResults()
                selectedItem = nil
            }) {
                Label("Scan Another", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.UI.buttonHeight)
                    .background(Color.green)
                    .cornerRadius(Constants.UI.cornerRadius)
            }

            Button(action: {
                // TODO: Implement share functionality
            }) {
                Label("Share Results", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.UI.buttonHeight)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(Constants.UI.cornerRadius)
            }
        }
    }
}

// MARK: - Ingredient Result Card

struct IngredientResultCard: View {
    let ingredient: Ingredient

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.smallSpacing) {
            HStack {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Label(ingredient.safetyLevel.localizedTitle, systemImage: ingredient.safetyLevel.icon)
                    .font(.caption)
                    .foregroundColor(ingredient.safetyLevel.color)
            }

            if let safetyInfo = ingredient.safetyInfo {
                if safetyInfo.hasHazards {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(safetyInfo.hazardStatements.prefix(2)) { hazard in
                            Text("• \(hazard.statement)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if safetyInfo.hazardStatements.count > 2 {
                            Text("+ \(safetyInfo.hazardStatements.count - 2) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No known hazards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Safety information not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(Constants.UI.smallCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                .stroke(ingredient.safetyLevel.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    CameraScanView()
        .withDependencies()
}
