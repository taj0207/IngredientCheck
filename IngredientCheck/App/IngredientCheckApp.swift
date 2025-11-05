//
//  IngredientCheckApp.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import SwiftUI

@main
struct IngredientCheckApp: App {

    // MARK: - Properties

    @StateObject private var appState = AppState()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .withDependencies(DIContainer.shared)
                .onAppear {
                    setupApp()
                }
        }
    }

    // MARK: - Setup

    private func setupApp() {
        print("========================================")
        print("🚀 APP STARTED - IngredientCheck v\(Constants.appVersion)")
        print("========================================")
        Logger.info("IngredientCheck app starting - version \(Constants.appVersion)", category: .general)
        Logger.info("Environment: \(AppEnvironment.current)", category: .general)
        Logger.info("OCR Provider: \(FeatureFlags.primaryOCRProvider.displayName)", category: .general)
    }
}

// MARK: - App State

/// Global app state
class AppState: ObservableObject {
    @Published var isOnboardingComplete: Bool

    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(
            forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding
        )
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        isOnboardingComplete = true
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.container) var container

    var body: some View {
        if appState.isOnboardingComplete || !FeatureFlags.requireAuthentication {
            MainTabView()
        } else {
            OnboardingView(appState: appState)
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CameraScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }

            ScanHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .accentColor(.green)
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @Environment(\.container) var container

    var body: some View {
        VStack(spacing: Constants.UI.largeSpacing) {
            Spacer()

            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("IngredientCheck")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Scan ingredients and check their safety instantly")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.UI.largeSpacing)

            Spacer()

            Button(action: {
                Task {
                    // Sign in anonymously
                    _ = try? await container.authenticationService.signInAnonymously()
                    appState.completeOnboarding()
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.UI.buttonHeight)
                    .background(Color.green)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
            .padding(.horizontal, Constants.UI.largeSpacing)
            .padding(.bottom, Constants.UI.largeSpacing)
        }
    }
}
