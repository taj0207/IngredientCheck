#!/bin/bash

# Diagnostic script for IngredientCheck app

echo "🔍 IngredientCheck Diagnostic Tool"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Xcode is installed
echo "✓ Checking Xcode..."
if command -v xcodebuild &> /dev/null; then
    xcodebuild -version | head -1
else
    echo "  ❌ Xcode not found!"
    exit 1
fi

echo ""

# Check if project exists
echo "✓ Checking project file..."
if [ -f "IngredientCheck.xcodeproj/project.pbxproj" ]; then
    echo "  ✓ IngredientCheck.xcodeproj found"
else
    echo "  ❌ Project file not found!"
    exit 1
fi

echo ""

# Check available simulators
echo "✓ Available iOS Simulators:"
xcrun simctl list devices available | grep "iPhone" | head -5

echo ""

# Try a simple build
echo "✓ Testing build (this may take a moment)..."
if xcodebuild -project IngredientCheck.xcodeproj \
  -scheme IngredientCheck \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build > /tmp/ingredient_build.log 2>&1; then
    echo "  ✅ Build SUCCEEDED"
else
    echo "  ❌ Build FAILED"
    echo ""
    echo "Last 20 lines of build log:"
    tail -20 /tmp/ingredient_build.log
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All checks passed!"
echo ""
echo "To run the app:"
echo "  1. Open: open IngredientCheck.xcodeproj"
echo "  2. Press: Cmd + R"
echo ""
echo "Check Xcode console for any runtime errors."
