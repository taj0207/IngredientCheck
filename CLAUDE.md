# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**IngredientCheck** is an iOS app that uses camera/photo library to scan ingredient lists and verify them against EU ECHA (European Chemicals Agency) and other safety databases. The app identifies red flags and warnings about potentially harmful ingredients.

### Core Features
- Photo capture and library access for ingredient lists
- LLM-powered OCR (GPT-4 Vision or Claude Vision) for accurate ingredient extraction
- Real-time safety checking against EU ECHA database
- OAuth authentication (Sign in with Apple, Google Sign In) for future cloud sync
- Offline-capable with direct API integration

### Technology Stack
- **Platform**: iOS 16.0+ (native)
- **UI Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Architecture**: MVVM + Repository Pattern + Service Layer
- **OCR**: LLM-based (GPT-4 Vision API or Claude API with vision)
- **Authentication**: AuthenticationServices (Sign in with Apple), GoogleSignIn SDK
- **Database**: CoreData (for local caching only, no primary storage)
- **Networking**: URLSession with async/await
- **Image Processing**: UIKit, Vision framework (for preprocessing)

## Architecture Principles

### Backend-Ready Architecture
The app is designed **without a backend initially** but architected for easy migration to cloud backend with minimal code changes:

1. **Repository Pattern**: All data access goes through repository interfaces
2. **Service Layer**: Business logic separated from data sources
3. **Protocol-Oriented**: All external dependencies defined as protocols
4. **Environment Configuration**: API endpoints and feature flags configurable per environment

### Key Architectural Decisions

```
┌─────────────────────────────────────────┐
│           SwiftUI Views                 │
│         (Presentation Layer)            │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│         ViewModels (MVVM)               │
│      (Presentation Logic)               │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│      Service Layer (Protocols)          │
│  - IngredientService                    │
│  - AuthenticationService                │
│  - OCRService                           │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│   Repository Layer (Protocols)          │
│  - IngredientRepository                 │
│  - UserRepository                       │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼─────────┐  ┌──────▼──────────┐
│   Remote    │  │  Local Cache    │
│ Data Source │  │ (CoreData)      │
│ (ECHA API)  │  │                 │
└─────────────┘  └─────────────────┘
```

**Migration Path**: When adding backend, only implement new `RemoteRepository` implementations - services and views remain unchanged.

## Project Structure

```
IngredientCheck/
├── App/
│   ├── IngredientCheckApp.swift          # App entry point
│   └── AppDelegate.swift                 # App lifecycle
├── Core/
│   ├── Configuration/
│   │   ├── Environment.swift             # Environment config (Dev/Staging/Prod)
│   │   ├── APIConfig.swift               # API endpoints and keys
│   │   └── FeatureFlags.swift            # Feature toggles
│   ├── Extensions/
│   │   ├── String+Extensions.swift
│   │   ├── Image+Extensions.swift
│   │   └── View+Extensions.swift
│   └── Utilities/
│       ├── Logger.swift                  # Logging utility
│       └── Constants.swift
├── Domain/
│   ├── Models/
│   │   ├── Ingredient.swift              # Core domain model
│   │   ├── SafetyInfo.swift              # Safety classification
│   │   ├── ScanResult.swift
│   │   └── User.swift
│   ├── Protocols/
│   │   ├── Repositories/
│   │   │   ├── IngredientRepositoryProtocol.swift
│   │   │   └── UserRepositoryProtocol.swift
│   │   └── Services/
│   │       ├── IngredientServiceProtocol.swift
│   │       ├── OCRServiceProtocol.swift
│   │       └── AuthenticationServiceProtocol.swift
│   └── UseCases/
│       ├── ScanIngredientUseCase.swift
│       └── CheckIngredientSafetyUseCase.swift
├── Data/
│   ├── Repositories/
│   │   ├── IngredientRepositoryImpl.swift
│   │   └── UserRepositoryImpl.swift
│   ├── DataSources/
│   │   ├── Remote/
│   │   │   ├── ECHAAPIClient.swift       # ECHA database API
│   │   │   ├── LLMOCRClient.swift        # GPT-4V or Claude Vision
│   │   │   └── NetworkClient.swift
│   │   └── Local/
│   │       ├── CoreData/
│   │       │   ├── PersistenceController.swift
│   │       │   └── Models/               # CoreData models
│   │       └── UserDefaultsManager.swift
│   └── DTOs/
│       ├── ECHAResponse.swift
│       └── OCRResponse.swift
├── Presentation/
│   ├── Common/
│   │   ├── Components/
│   │   │   ├── CameraView.swift
│   │   │   ├── PhotoPickerView.swift
│   │   │   ├── LoadingView.swift
│   │   │   └── SafetyBadge.swift
│   │   └── Modifiers/
│   ├── Screens/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewModel.swift
│   │   ├── Camera/
│   │   │   ├── CameraScanView.swift
│   │   │   └── CameraScanViewModel.swift
│   │   ├── Results/
│   │   │   ├── IngredientResultsView.swift
│   │   │   ├── IngredientDetailView.swift
│   │   │   └── ResultsViewModel.swift
│   │   ├── History/
│   │   │   ├── ScanHistoryView.swift
│   │   │   └── HistoryViewModel.swift
│   │   └── Auth/
│   │       ├── LoginView.swift
│   │       └── AuthViewModel.swift
│   └── Navigation/
│       └── AppCoordinator.swift
├── Services/
│   ├── IngredientServiceImpl.swift
│   ├── OCRServiceImpl.swift              # LLM-based OCR
│   ├── AuthenticationServiceImpl.swift
│   └── ECHAServiceImpl.swift
├── DependencyInjection/
│   └── DIContainer.swift                 # Dependency injection container
└── Resources/
    ├── Assets.xcassets/
    ├── Localizable.strings
    └── Info.plist
```

## Development Setup

### Prerequisites
```bash
# Install Xcode 15.0 or later from App Store
# Install CocoaPods (if using)
sudo gem install cocoapods

# Or use Swift Package Manager (recommended)
```

### Environment Configuration

Create `IngredientCheck/Core/Configuration/Secrets.swift` (git-ignored):
```swift
enum Secrets {
    static let openAIAPIKey = "sk-..."  // Or Claude API key
    static let googleOAuthClientID = "your-client-id"
    // ECHA API is public, no key needed
}
```

### Build and Run

**Using Xcode:**
1. Open `IngredientCheck.xcodeproj` or `IngredientCheck.xcworkspace`
2. Select target device/simulator
3. Press `Cmd + R` to build and run
4. Press `Cmd + U` to run tests

**Using xcodebuild (CLI):**
```bash
# Build for simulator
xcodebuild -scheme IngredientCheck -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run tests
xcodebuild test -scheme IngredientCheck -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Build for device (requires signing)
xcodebuild -scheme IngredientCheck -destination 'generic/platform=iOS' -configuration Release build
```

### Running Single Tests
```bash
# Run specific test class
xcodebuild test -scheme IngredientCheck -only-testing:IngredientCheckTests/OCRServiceTests

# Run specific test method
xcodebuild test -scheme IngredientCheck -only-testing:IngredientCheckTests/OCRServiceTests/testExtractIngredients
```

## Key Implementation Details

### LLM-Based OCR

The app uses LLM vision models instead of traditional OCR for superior accuracy:

**OCRServiceImpl.swift** should:
- Accept UIImage as input
- Convert to base64 or API-specific format
- Send to GPT-4 Vision or Claude API with prompt:
  ```
  "Extract all ingredients from this product label.
   Return a JSON array of ingredient names in the exact order shown.
   Format: {\"ingredients\": [\"ingredient1\", \"ingredient2\", ...]}"
  ```
- Parse JSON response into structured data
- Handle errors gracefully

**API Choice:**
- **GPT-4 Vision**: Better for English, very accurate
- **Claude Vision**: Better for mixed languages, more cost-effective
- Consider making this configurable via feature flag

### ECHA Database Integration

**ECHA APIs to use:**
1. **Information Platform API**: https://echa.europa.eu/information-on-chemicals/information-platform
2. **Dissemination API**: For REACH registered substances
3. **CLP Inventory**: Classification and labelling

**Implementation Notes:**
- ECHA APIs are public REST APIs (no authentication)
- Cache responses locally for 24 hours (CoreData)
- Match ingredients by CAS number or EC number (more reliable than names)
- Handle multiple languages in ingredient names

### OAuth Implementation

**Sign in with Apple** (Required for App Store):
```swift
// Use AuthenticationServices framework
import AuthenticationServices

// Implement ASAuthorizationControllerDelegate
// Store user ID and tokens in Keychain
```

**Google Sign In** (Optional):
```swift
// Use GoogleSignIn SDK via SPM
// Store tokens securely for future backend sync
```

**Important**: Even without backend, implement token storage properly:
- Store access tokens in Keychain
- Store user basic info in UserDefaults or CoreData
- Prepare for backend token validation (add `backendAPIKey` field)

### Repository Pattern for Easy Migration

Current (No Backend):
```swift
class IngredientRepositoryImpl: IngredientRepositoryProtocol {
    private let echaAPI: ECHAAPIClient
    private let localCache: CoreDataManager

    func checkSafety(ingredient: String) async throws -> SafetyInfo {
        // Try cache first
        if let cached = try? await localCache.fetchSafetyInfo(for: ingredient) {
            return cached
        }

        // Fetch from ECHA directly
        let info = try await echaAPI.fetchSafetyInfo(for: ingredient)

        // Cache result
        try? await localCache.save(safetyInfo: info)

        return info
    }
}
```

Future (With Backend):
```swift
class IngredientRepositoryImpl: IngredientRepositoryProtocol {
    private let backendAPI: BackendAPIClient  // Just swap this
    private let localCache: CoreDataManager

    func checkSafety(ingredient: String) async throws -> SafetyInfo {
        // Same interface, different implementation
        // Now fetch from your backend instead of ECHA directly
        return try await backendAPI.checkIngredientSafety(ingredient)
    }
}
```

**ViewModels and Services don't change at all!**

### Dependency Injection Setup

Use a simple DI container to make swapping implementations easy:

```swift
// DIContainer.swift
class DIContainer {
    static let shared = DIContainer()

    // Toggle between implementations here
    lazy var ingredientRepository: IngredientRepositoryProtocol = {
        if FeatureFlags.useBackend {
            return BackendIngredientRepository()  // Future
        } else {
            return DirectECHARepository()  // Current
        }
    }()

    // Similar pattern for all services
}
```

## API Integration Specifics

### ECHA API Example
```swift
// Base URL
let echaBaseURL = "https://echa.europa.eu/api/diss"

// Search by substance name
GET /substances?name=<ingredient_name>

// Get substance details
GET /substances/<id>

// Parse hazard classifications:
// - GHS classifications (pictograms)
// - H-statements (hazard statements)
// - P-statements (precautionary statements)
```

### LLM OCR API Example (Claude)
```swift
let anthropicAPI = "https://api.anthropic.com/v1/messages"

// Request body:
{
  "model": "claude-sonnet-4-5-20250929",
  "max_tokens": 1024,
  "messages": [{
    "role": "user",
    "content": [
      {
        "type": "image",
        "source": {
          "type": "base64",
          "media_type": "image/jpeg",
          "data": "<base64_image>"
        }
      },
      {
        "type": "text",
        "text": "Extract ingredients from this product label..."
      }
    ]
  }]
}
```

## Testing Strategy

### Unit Tests
- Test ViewModels with mock services
- Test repositories with mock data sources
- Test service business logic
- Target: 80%+ coverage

### Integration Tests
- Test ECHA API client with real API (rate-limited)
- Test LLM OCR with sample images
- Test OAuth flows (mock where necessary)

### UI Tests
- Test complete user flows
- Camera permission handling
- Photo picker integration
- Results display

## Security Considerations

1. **API Keys**: Never commit to git
   - Use Secrets.swift (git-ignored)
   - Or use xcconfig files with environment variables

2. **OAuth Tokens**: Store in Keychain only

3. **Image Privacy**:
   - Images sent to LLM API should not be stored by provider
   - Check API provider's data usage policy
   - Consider on-device image preprocessing to remove non-label content

4. **HTTPS Only**: All network calls must use HTTPS

## Localization

Support multiple languages:
- Traditional Chinese (zh-Hant)
- English (en)
- ECHA database returns multilingual data (handle accordingly)

## Performance Optimization

1. **Image Compression**: Compress images before sending to LLM API
2. **Caching**: Cache ECHA results for 24 hours
3. **Batch Requests**: When checking multiple ingredients, batch ECHA API calls
4. **Background Processing**: Use background queues for API calls
5. **Lazy Loading**: In history view, load details on demand

## Future Backend Migration Checklist

When ready to add backend:

1. ✅ Create new repository implementations (e.g., `BackendIngredientRepository`)
2. ✅ Update `FeatureFlags.useBackend = true`
3. ✅ Add backend API client (similar to ECHAAPIClient)
4. ✅ Implement backend authentication (pass OAuth tokens)
5. ✅ Update DIContainer to use new repositories
6. ⚠️ No changes needed to: ViewModels, Views, Service protocols, Domain models

## Common Development Tasks

### Adding a New Ingredient Source
1. Create new API client in `Data/DataSources/Remote/`
2. Update `IngredientServiceImpl` to aggregate results
3. No changes needed to UI layer

### Adding New OAuth Provider
1. Add SDK via Swift Package Manager
2. Implement provider in `Services/AuthenticationServiceImpl.swift`
3. Update `LoginView` to show new button
4. Store tokens in Keychain

### Updating Safety Criteria
1. Update `SafetyInfo` model in `Domain/Models/`
2. Update parsing logic in ECHA API client
3. Update UI components to display new info

## Debugging

### ECHA API Issues
```bash
# Test ECHA API directly
curl "https://echa.europa.eu/api/diss/substances?name=benzene"
```

### LLM OCR Not Working
- Check API key validity
- Verify image size (should be < 20MB)
- Check image format (JPEG, PNG supported)
- Review API rate limits

### OAuth Failures
- Verify Bundle ID matches OAuth console configuration
- Check redirect URIs are correctly configured
- Ensure proper entitlements for Sign in with Apple

## Resources

- ECHA Database: https://echa.europa.eu/information-on-chemicals
- ECHA API Docs: https://echa.europa.eu/support/diss-dissemination-platform
- OpenAI Vision API: https://platform.openai.com/docs/guides/vision
- Claude API: https://docs.anthropic.com/claude/docs/vision
- Apple Authentication: https://developer.apple.com/documentation/authenticationservices
- Google Sign-In iOS: https://developers.google.com/identity/sign-in/ios
