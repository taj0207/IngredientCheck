#!/bin/bash

# IngredientCheck Build Script
# This script builds the iOS app using xcodebuild

set -e  # Exit on error

PROJECT="IngredientCheck.xcodeproj"
SCHEME="IngredientCheck"
SIMULATOR="iPhone 15 Pro"

echo "🔨 Building IngredientCheck..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clean build folder
echo "🧹 Cleaning build folder..."
xcodebuild clean \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  > /dev/null 2>&1

# Build the project
echo "🔧 Building for iOS Simulator ($SIMULATOR)..."
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  -configuration Debug

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build completed successfully!"
echo ""
echo "To run in simulator:"
echo "  open IngredientCheck.xcodeproj"
echo "  Press Cmd+R to run"
