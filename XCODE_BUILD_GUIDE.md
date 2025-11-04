# 🔨 Xcode Build Guide

Complete step-by-step instructions to build and run IngredientCheck in Xcode.

## Prerequisites

✅ **Required:**
- macOS (Monterey 12.0 or later recommended)
- Xcode 14.0+ (download from App Store or developer.apple.com)
- OpenAI API account with API key
- iOS 16.0+ device or simulator

## Step 1: Get OpenAI API Key

1. Visit https://platform.openai.com/api-keys
2. Sign in or create an account
3. Click **"Create new secret key"**
4. Name it: `IngredientCheck-iOS`
5. **Copy the key** (starts with `sk-proj-...`)
6. ⚠️ Save it somewhere safe - you can't see it again!

**Cost**: GPT-5-mini is ~$0.001 per scan (~1000 scans = $1)

---

## Step 2: Create Secrets File

1. Navigate to your project directory in Terminal:
```bash
cd /path/to/IngredientCheck
```

2. Copy the example secrets file:
```bash
cp IngredientCheck/Core/Configuration/Secrets.swift.example \
   IngredientCheck/Core/Configuration/Secrets.swift
```

3. Open `Secrets.swift` and paste your API key:
```swift
enum Secrets {
    static let openAIAPIKey = "sk-proj-YOUR_ACTUAL_KEY_HERE"  // ← Paste here
    static let googleOAuthClientID: String? = nil
}
```

4. Save the file

---

## Step 3: Create Xcode Project

### Option A: Using Xcode GUI (Recommended)

1. **Open Xcode** → **File** → **New** → **Project**

2. **Choose template:**
   - Select **iOS** tab
   - Click **App**
   - Click **Next**

3. **Fill in project details:**
   ```
   Product Name:        IngredientCheck
   Team:                [Select your Apple ID or leave as None]
   Organization ID:     com.yourname (e.g., com.john)
   Bundle Identifier:   com.yourname.IngredientCheck
   Interface:           SwiftUI ✅
   Language:            Swift ✅
   Storage:             None
   ```
   - ✅ **Uncheck** "Use Core Data"
   - ✅ **Uncheck** "Include Tests" (optional)

4. **Save location:**
   - Navigate to: `/path/to/IngredientCheck/`
   - ⚠️ Save **inside** the existing IngredientCheck folder
   - Click **Create**

5. **Delete auto-generated files** (we already have these):
   - Right-click and delete:
     - `IngredientCheckApp.swift` (old one)
     - `ContentView.swift`
   - Select **Move to Trash**

---

## Step 4: Add Source Files to Xcode

### Method 1: Drag and Drop

1. In **Xcode Project Navigator** (left sidebar)
2. **Delete** the auto-generated `IngredientCheck` group (keep target)
3. **Drag these folders** from Finder into Xcode:
   - `IngredientCheck/App/`
   - `IngredientCheck/Core/`
   - `IngredientCheck/Domain/`
   - `IngredientCheck/Data/`
   - `IngredientCheck/Services/`
   - `IngredientCheck/Presentation/`
   - `IngredientCheck/DependencyInjection/`
   - `IngredientCheck/Resources/`

4. In the popup dialog:
   - ✅ Check **"Copy items if needed"**
   - ✅ Select **"Create groups"**
   - ✅ Check **"IngredientCheck" target**
   - Click **Finish**

### Method 2: Add Files Menu

1. Right-click on **IngredientCheck** group
2. Select **"Add Files to IngredientCheck..."**
3. Navigate to your source folders
4. Select all folders (hold Cmd to multi-select)
5. Configure options (same as above)
6. Click **Add**

---

## Step 5: Configure Project Settings

### General Tab

1. Select **IngredientCheck** project in Navigator
2. Select **IngredientCheck** target
3. Go to **General** tab

**Settings:**
```
Display Name:           IngredientCheck
Bundle Identifier:      com.yourname.IngredientCheck
Version:                1.0
Build:                  1
Minimum Deployments:    iOS 16.0 ✅
iPhone Orientation:     Portrait ✅
iPad Orientation:       All
Status Bar Style:       Default
```

### Info Tab

Verify these permissions are added (should be from Resources/Info.plist):

```xml
<key>NSCameraUsageDescription</key>
<string>IngredientCheck needs camera access to scan ingredient labels</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>IngredientCheck needs photo library access to select product images</string>
```

If missing, add them:
1. Click **+** button
2. Select **Privacy - Camera Usage Description**
3. Add description: "IngredientCheck needs camera access to scan ingredient labels"
4. Repeat for **Privacy - Photo Library Usage Description**

### Signing & Capabilities

1. Go to **Signing & Capabilities** tab
2. Check **"Automatically manage signing"**
3. Select your **Team** (Apple ID)
4. Xcode will generate a provisioning profile

---

## Step 6: Verify File Structure

Your Xcode project should look like this:

```
IngredientCheck
├── App
│   └── IngredientCheckApp.swift
├── Core
│   ├── Configuration
│   │   ├── APIConfig.swift
│   │   ├── Environment.swift
│   │   ├── FeatureFlags.swift
│   │   └── Secrets.swift ⚠️ (YOU CREATED THIS)
│   └── Utilities
│       ├── Constants.swift
│       └── Logger.swift
├── Domain
│   ├── Models
│   └── Protocols
├── Data
│   ├── DataSources
│   └── Repositories
├── Services
├── Presentation
│   ├── Screens
│   └── Common
├── DependencyInjection
└── Resources
    └── Info.plist
```

---

## Step 7: Build the Project

### Build for Simulator

1. Select target device:
   - Click device dropdown (next to play button)
   - Choose **iPhone 15 Pro** (or any iOS 16+ simulator)

2. Build the project:
   - Press **Cmd + B** (Build)
   - Or click **Product** → **Build**

3. Wait for build to complete
   - ✅ Should see: **"Build Succeeded"**

### Run on Simulator

1. Press **Cmd + R** (Run)
2. Simulator will launch
3. App should open automatically

### Run on Physical Device

1. Connect iPhone via USB
2. Trust computer on device (if prompted)
3. Select your iPhone from device dropdown
4. Press **Cmd + R**
5. ⚠️ If error: Check Signing & Capabilities

---

## Step 8: Test the App

### Test Photo Library (Simulator)

1. Launch app
2. Tap **"Choose from Library"**
3. Select a test image
4. Watch OCR process
5. View results

**Add test images to simulator:**
- Drag image files into simulator
- They'll be saved to Photos app

### Test Camera (Physical Device Only)

1. Launch app on real iPhone
2. Tap **"Take Photo"**
3. Grant camera permission
4. Take photo of ingredient list
5. View analysis results

⚠️ **Camera doesn't work on simulator** - it's hardware-dependent

---

## Troubleshooting

### ❌ Build Error: "Cannot find 'Secrets' in scope"

**Problem**: Forgot to create `Secrets.swift`

**Fix**:
```bash
cp IngredientCheck/Core/Configuration/Secrets.swift.example \
   IngredientCheck/Core/Configuration/Secrets.swift
```
Then add your OpenAI API key.

---

### ❌ Build Error: "No such module 'AVFoundation'"

**Problem**: Missing framework

**Fix**:
1. Select target → **General** tab
2. Scroll to **Frameworks, Libraries, and Embedded Content**
3. Click **+**
4. Add `AVFoundation.framework`

---

### ❌ Runtime Error: "Invalid API key"

**Problem**: Wrong or missing OpenAI API key

**Fix**:
1. Open `Secrets.swift`
2. Verify your API key is correct
3. Ensure no spaces or quotes inside the string
4. Format: `"sk-proj-..."`

---

### ❌ Build Error: Multiple files found

**Problem**: Duplicate files (auto-generated + our files)

**Fix**:
1. In Project Navigator, search for duplicates
2. Delete auto-generated versions (ContentView.swift, etc.)
3. Keep only our versions

---

### ❌ Signing Error: "Failed to create provisioning profile"

**Problem**: Need Apple Developer account

**Fix Option 1** (Free):
1. Use your Apple ID
2. Signing & Capabilities → Select your Apple ID team
3. Change Bundle ID to be unique: `com.yourname.IngredientCheck`

**Fix Option 2** (Paid):
1. Join Apple Developer Program ($99/year)
2. Access full signing capabilities

---

### ❌ Camera Permission Denied

**Problem**: Forgot to grant camera access

**Fix**:
1. **Settings** → **Privacy & Security** → **Camera**
2. Enable **IngredientCheck**
3. Restart app

---

### ❌ OCR Returns Empty Results

**Possible causes:**
- Image quality too low
- Text not readable
- API rate limit reached
- API key expired

**Fix**:
1. Use clear, well-lit photos
2. Check API quota: https://platform.openai.com/usage
3. Verify API key is still valid

---

### ❌ ECHA API Returns No Data

**Problem**: Ingredient not in EU database

**Expected**: Not all ingredients are registered in ECHA
- App shows "Safety information not available"
- This is **normal** for some ingredients

---

## Build Configuration Tips

### Debug vs Release

**Debug** (default):
- Includes debug symbols
- Slower performance
- Easier to debug

**Release**:
1. **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Build Configuration** → **Release**
3. Use for final testing

### Clean Build

If having issues:
1. **Product** → **Clean Build Folder** (Shift + Cmd + K)
2. Rebuild (Cmd + B)

### Derived Data

Clear cached build data:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/IngredientCheck-*
```

---

## Performance Tips

### Optimize Build Time

1. **Enable Build Parallelization**:
   - Xcode → **Preferences** → **Locations**
   - Set **Derived Data** to default location
   - **Build System**: New Build System

2. **Reduce Indexing**:
   - Xcode → **Preferences** → **Locations**
   - Close other projects

### Optimize Runtime

1. **Use Release Build** for testing performance
2. **Profile with Instruments**:
   - Product → Profile (Cmd + I)
   - Choose Time Profiler or Memory Leaks

---

## Advanced: Command Line Build

If you prefer Terminal:

```bash
# Build for simulator
xcodebuild -scheme IngredientCheck \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# Run on simulator
xcodebuild -scheme IngredientCheck \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -allowProvisioningUpdates \
  test
```

---

## Next Steps After Build

✅ **App built successfully?**

1. **Test all features**:
   - [ ] Camera capture
   - [ ] Photo library selection
   - [ ] OCR extraction
   - [ ] Safety analysis
   - [ ] Results display

2. **Check documentation**:
   - [SETUP.md](./SETUP.md) - General setup
   - [CAMERA_GUIDE.md](./CAMERA_GUIDE.md) - Camera implementation
   - [CLAUDE.md](./CLAUDE.md) - Architecture details

3. **Customize**:
   - Add app icon (Assets.xcassets)
   - Modify color scheme
   - Add localization (Chinese/English)

4. **Deploy**:
   - TestFlight (beta testing)
   - App Store submission

---

## Quick Reference Commands

```bash
# Create Secrets file
cp IngredientCheck/Core/Configuration/Secrets.swift.example \
   IngredientCheck/Core/Configuration/Secrets.swift

# Open in Xcode
open IngredientCheck.xcodeproj

# Build from command line
xcodebuild -scheme IngredientCheck build

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/IngredientCheck-*
```

---

## Need Help?

📚 **Documentation**:
- [Apple's Xcode Guide](https://developer.apple.com/xcode/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [OpenAI API Docs](https://platform.openai.com/docs)

💬 **Issues**:
- Check [README.md](./README.md)
- Review [CLAUDE.md](./CLAUDE.md)
- Create GitHub issue

---

**You're all set! Happy coding! 🚀📱**
