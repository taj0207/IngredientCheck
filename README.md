# IngredientCheck

An iOS app that scans ingredient lists from product labels and verifies them against EU ECHA and other safety databases to identify potentially harmful ingredients.

## Features

- 📸 Camera and photo library integration for scanning ingredient lists
- 🤖 LLM-powered OCR using GPT-5-mini for accurate ingredient extraction
- ⚠️ Real-time safety checking against EU ECHA database
- 🔐 OAuth authentication (Sign in with Apple, Google Sign In)
- 💾 Local caching for offline access
- 🌍 Multi-language support (繁體中文, English)

## Technology Stack

- **Platform**: iOS 16.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Repository Pattern
- **OCR**: GPT-5-mini Vision API
- **Safety Data**: EU ECHA API

## Getting Started

### Prerequisites

- macOS 13.0+ with Xcode 15.0+
- iOS 16.0+ device or simulator
- OpenAI API key for GPT-5-mini

### Setup

1. Clone the repository:
```bash
git clone https://github.com/taj0207/IngredientCheck.git
cd IngredientCheck
```

2. Create `IngredientCheck/Core/Configuration/Secrets.swift`:
```swift
enum Secrets {
    static let openAIAPIKey = "sk-proj-..."
    static let googleOAuthClientID = "your-client-id" // Optional
}
```

3. Open `IngredientCheck.xcodeproj` in Xcode

4. Select your target device and press `Cmd + R` to build and run

## Project Structure

See [CLAUDE.md](./CLAUDE.md) for detailed architecture documentation.

## Development

### Building
```bash
xcodebuild -scheme IngredientCheck -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Testing
```bash
xcodebuild test -scheme IngredientCheck -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## License

MIT License - see [LICENSE](LICENSE) for details

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## Support

For questions and support, please open an issue on GitHub.
