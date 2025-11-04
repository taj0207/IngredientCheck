//
//  HomeView.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import SwiftUI

struct HomeView: View {
    @Environment(\.container) var container
    @StateObject private var viewModel: HomeViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            authService: DIContainer.shared.authenticationService,
            userRepository: DIContainer.shared.userRepository
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.UI.largeSpacing) {
                    // Header
                    headerView

                    // Quick Actions
                    quickActionsView

                    // Recent Scans
                    if !viewModel.scanHistory.isEmpty {
                        recentScansView
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("IngredientCheck")
            .refreshable {
                if let userId = viewModel.user?.id {
                    await viewModel.loadScanHistory(for: userId)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(alignment: .leading, spacing: Constants.UI.smallSpacing) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Scan product labels to check ingredient safety")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickActionsView: some View {
        VStack(spacing: Constants.UI.spacing) {
            QuickActionCard(
                icon: "camera.fill",
                title: "Scan Label",
                description: "Take a photo of ingredients",
                color: .green
            )

            QuickActionCard(
                icon: "photo.fill",
                title: "Choose Photo",
                description: "Select from your library",
                color: .blue
            )
        }
    }

    private var recentScansView: some View {
        VStack(alignment: .leading, spacing: Constants.UI.spacing) {
            Text("Recent Scans")
                .font(.headline)

            ForEach(viewModel.scanHistory.prefix(5)) { scan in
                NavigationLink(destination: ScanResultDetailView(scanResult: scan)) {
                    ScanResultRow(scanResult: scan)
                }
            }
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: Constants.UI.spacing) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(Constants.UI.smallCornerRadius)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(radius: 2)
    }
}

// MARK: - Scan Result Row

struct ScanResultRow: View {
    let scanResult: ScanResult

    var body: some View {
        HStack {
            Image(systemName: scanResult.overallSafetyLevel.icon)
                .foregroundColor(scanResult.overallSafetyLevel.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(scanResult.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(scanResult.ingredientCount) ingredients • \(scanResult.scanDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, Constants.UI.smallSpacing)
    }
}

// MARK: - Scan Result Detail View (Placeholder)

struct ScanResultDetailView: View {
    let scanResult: ScanResult

    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Overall Safety")
                    Spacer()
                    Label(scanResult.overallSafetyLevel.localizedTitle, systemImage: scanResult.overallSafetyLevel.icon)
                        .foregroundColor(scanResult.overallSafetyLevel.color)
                }

                HStack {
                    Text("Ingredients")
                    Spacer()
                    Text("\(scanResult.ingredientCount)")
                        .foregroundColor(.secondary)
                }

                if scanResult.hasConcerns {
                    HStack {
                        Text("Concerns")
                        Spacer()
                        Text("\(scanResult.concernCount)")
                            .foregroundColor(.red)
                    }
                }
            }

            Section("Ingredients") {
                ForEach(scanResult.ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient)
                }
            }
        }
        .navigationTitle("Scan Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ingredient Row

struct IngredientRow: View {
    let ingredient: Ingredient

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.subheadline)

                if let safetyInfo = ingredient.safetyInfo, safetyInfo.hasHazards {
                    Text(safetyInfo.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemImage: ingredient.safetyLevel.icon)
                .foregroundColor(ingredient.safetyLevel.color)
        }
    }
}

// MARK: - Scan History View

struct ScanHistoryView: View {
    @Environment(\.container) var container
    @StateObject private var viewModel: HomeViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            authService: DIContainer.shared.authenticationService,
            userRepository: DIContainer.shared.userRepository
        ))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.scanHistory) { scan in
                    NavigationLink(destination: ScanResultDetailView(scanResult: scan)) {
                        ScanResultRow(scanResult: scan)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await viewModel.deleteScan(viewModel.scanHistory[index])
                        }
                    }
                }
            }
            .navigationTitle("Scan History")
            .overlay {
                if viewModel.scanHistory.isEmpty {
                    VStack(spacing: Constants.UI.spacing) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No scans yet")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Start scanning ingredients to build your history")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
        }
    }
}
