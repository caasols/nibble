#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_NAME="${APP_NAME:-Nibble}"
RELEASE_TAG="${RELEASE_TAG:-dev}"
SCRATCH_PATH="${SCRATCH_PATH:-$HOME/Library/Caches/nibble-spm-build}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"

APPLE_SIGNING_IDENTITY="${APPLE_SIGNING_IDENTITY:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_NOTARY_KEY_ID="${APPLE_NOTARY_KEY_ID:-}"
APPLE_NOTARY_ISSUER_ID="${APPLE_NOTARY_ISSUER_ID:-}"
APPLE_NOTARY_API_KEY_PATH="${APPLE_NOTARY_API_KEY_PATH:-}"

APP_PATH="$DIST_DIR/${APP_NAME}.app"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${RELEASE_TAG}-macOS.zip"

mkdir -p "$DIST_DIR"
rm -rf "$APP_PATH" "$ZIP_PATH" "$ZIP_PATH.sha256"

echo "Building release app bundle..."
SCRATCH_PATH="$SCRATCH_PATH" "$ROOT_DIR/build.sh"

cp -R "$ROOT_DIR/build/${APP_NAME}.app" "$APP_PATH"

echo "Signing app with Developer ID identity..."
codesign --force --deep --options runtime --timestamp --sign "$APPLE_SIGNING_IDENTITY" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Packaging app zip..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Submitting for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
  --key "$APPLE_NOTARY_API_KEY_PATH" \
  --key-id "$APPLE_NOTARY_KEY_ID" \
  --issuer "$APPLE_NOTARY_ISSUER_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "Rebuilding zip to include stapled ticket..."
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Generating checksum..."
shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

echo "Release artifacts ready:"
echo "- App: $APP_PATH"
echo "- Zip: $ZIP_PATH"
echo "- SHA256: $ZIP_PATH.sha256"
