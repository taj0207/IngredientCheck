# Fix for Blank/White Screen Issue

## Problem
The app shows a blank/white screen because `HomeViewModel` was calling async methods in its `init()`, which causes crashes on iOS.

## ✅ Fix Applied

I've already fixed the code. The changes were:

### 1. HomeViewModel.swift (Line 28-37)
**Changed:** Removed async call from `init()`

```swift
// OLD - CAUSES CRASH
init(...) {
    self.authService = authService
    self.userRepository = userRepository
    Task {
        await loadUser()  // ❌ This crashes the app
    }
}

// NEW - FIXED ✅
init(...) {
    self.authService = authService
    self.userRepository = userRepository
    // Don't call async methods in init - it causes crashes
    // Let the view call loadUser() in .onAppear instead
}
```

### 2. HomeView.swift (Line 41-45)
**Added:** Call `loadUser()` in `.onAppear` instead

```swift
.navigationTitle("IngredientCheck")
.onAppear {
    Task {
        await viewModel.loadUser()  // ✅ Safe to call here
    }
}
```

## 🚀 Test the Fix

### Option 1: Rebuild in Xcode
```bash
open IngredientCheck.xcodeproj
# Press: Cmd + Shift + K (Clean)
# Press: Cmd + R (Run)
```

### Option 2: Command Line
```bash
xcodebuild -project IngredientCheck.xcodeproj \
  -scheme IngredientCheck \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  clean build run
```

## 📱 What You Should See Now

After running the app, you should see:

1. **Navigation Bar** with "IngredientCheck" title
2. **Welcome Section**:
   - "Welcome back!"
   - "Scan product labels to check ingredient safety"
3. **Two Action Cards**:
   - 🟢 Green card: "Scan Label" / "Take a photo of ingredients"
   - 🔵 Blue card: "Choose Photo" / "Select from your library"
4. **Bottom Tab Bar** with 3 tabs:
   - 🏠 Home
   - 📷 Scan
   - 🕐 History

## 🐛 If Still Blank

If you still see a blank screen:

### 1. Check Xcode Console
Look at the bottom panel in Xcode for red error messages. Common issues:

- **Missing Secrets.swift**: Check that `/IngredientCheck/Core/Configuration/Secrets.swift` exists
- **API Key issues**: Your OpenAI key should start with `sk-proj-`

### 2. Reset Simulator
```bash
# Close simulator
xcrun simctl shutdown all

# Erase all data
xcrun simctl erase all

# Try again
open IngredientCheck.xcodeproj
# Press Cmd + R
```

### 3. Check Bundle ID Signing
In Xcode:
1. Select project → IngredientCheck target
2. Go to "Signing & Capabilities"
3. Enable "Automatically manage signing"
4. Select your Apple ID team

### 4. Use Simple Test View
If nothing works, uncomment the test view in `IngredientCheckApp_Simple.swift` to verify the app can run at all.

## 📝 Technical Details

### Why Did This Happen?

**Problem**: SwiftUI views and ViewModels must be initialized synchronously. Calling `async` methods in `init()` causes the initialization to never complete, resulting in a blank screen.

**Solution**: Move async initialization to `.onAppear` or `.task` modifiers in the View.

### Best Practice

```swift
// ❌ BAD - Don't do this
class ViewModel: ObservableObject {
    init() {
        Task {
            await loadData()  // Crashes!
        }
    }
}

// ✅ GOOD - Do this instead
struct MyView: View {
    @StateObject var viewModel = ViewModel()

    var body: some View {
        Text("Hello")
            .task {  // or .onAppear
                await viewModel.loadData()
            }
    }
}
```

## 🎯 Next Steps

Once the app shows properly:

1. **Test the Home tab** - Should show welcome message
2. **Test the Scan tab** - Should show camera UI
3. **Test the History tab** - Should show empty state

If any specific feature doesn't work, let me know which one and I'll help debug it!
