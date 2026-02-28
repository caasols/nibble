#!/bin/bash

set -e

echo "Building Nibble..."

APP_NAME="Nibble"
SCRATCH_PATH="${SCRATCH_PATH:-$HOME/Library/Caches/nibble-spm-build}"
BUILD_DIR="${SCRATCH_PATH}/release"

# Navigate to project directory
cd "$(dirname "$0")"

# Clean previous build
if [ -d "build" ]; then
    echo "Cleaning previous build..."
    rm -rf build
fi

# Build the project
echo "Building with Swift Package Manager..."
swift build -c release --scratch-path "${SCRATCH_PATH}"

# Create app bundle
echo "Creating app bundle..."
BUNDLE_NAME="${APP_NAME}.app"

# Create app bundle structure
mkdir -p "build/${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "build/${BUNDLE_NAME}/Contents/Resources"

# Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "build/${BUNDLE_NAME}/Contents/MacOS/"
chmod +x "build/${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "${APP_NAME}/Resources/Info.plist" "build/${BUNDLE_NAME}/Contents/"

# Copy Assets if they exist
if [ -d "${APP_NAME}/Resources/Assets.xcassets" ]; then
    cp -r "${APP_NAME}/Resources/Assets.xcassets" "build/${BUNDLE_NAME}/Contents/Resources/"
fi

# Code sign the app (ad-hoc signing for local use)
echo "Code signing app..."
codesign --force --deep --sign - "build/${BUNDLE_NAME}" 2>/dev/null || echo "Warning: Code signing failed, but app may still work"

echo ""
echo "Build complete!"
echo "App bundle created at: build/${BUNDLE_NAME}"
echo "SwiftPM scratch path: ${SCRATCH_PATH}"
echo ""
echo "To run the app:"
echo "  open build/${BUNDLE_NAME}"
echo ""
echo "To install the app:"
echo "  cp -r build/${BUNDLE_NAME} /Applications/"
echo ""
echo "If you get a security warning, right-click the app and select Open, or run:"
echo "  xattr -cr /Applications/${BUNDLE_NAME}"
