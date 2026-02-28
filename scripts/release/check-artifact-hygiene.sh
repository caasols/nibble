#!/bin/bash

set -euo pipefail

APP_PATH=""
ZIP_PATH=""
EXPECTED_BUNDLE_ID=""
EXPECTED_TOP_LEVEL="Nibble.app/"
SKIP_SIGNING_CHECK="${SKIP_SIGNING_CHECK:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-path)
      APP_PATH="$2"
      shift 2
      ;;
    --zip-path)
      ZIP_PATH="$2"
      shift 2
      ;;
    --expected-bundle-id)
      EXPECTED_BUNDLE_ID="$2"
      shift 2
      ;;
    --expected-top-level)
      EXPECTED_TOP_LEVEL="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$APP_PATH" || -z "$ZIP_PATH" || -z "$EXPECTED_BUNDLE_ID" ]]; then
  echo "Usage: $0 --app-path <path> --zip-path <path> --expected-bundle-id <bundle-id> [--expected-top-level <entry>]"
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH"
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Zip artifact not found: $ZIP_PATH"
  exit 1
fi

if [[ ! -x "$APP_PATH/Contents/MacOS/Nibble" ]]; then
  echo "Missing executable in app bundle: $APP_PATH/Contents/MacOS/Nibble"
  exit 1
fi

ACTUAL_BUNDLE_ID="$(defaults read "$APP_PATH/Contents/Info" CFBundleIdentifier)"
if [[ "$ACTUAL_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
  echo "Unexpected bundle ID. expected=$EXPECTED_BUNDLE_ID actual=$ACTUAL_BUNDLE_ID"
  exit 1
fi

if [[ "$SKIP_SIGNING_CHECK" != "1" ]]; then
  echo "Verifying code signature..."
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"

  echo "Assessing Gatekeeper policy..."
  spctl --assess --type exec --verbose=2 "$APP_PATH"
fi

ZIP_LIST="$(mktemp)"
zipinfo -1 "$ZIP_PATH" > "$ZIP_LIST"

if ! grep -qx "$EXPECTED_TOP_LEVEL" "$ZIP_LIST"; then
  echo "Missing expected top-level entry in zip: $EXPECTED_TOP_LEVEL"
  exit 1
fi

if grep -q '^__MACOSX/' "$ZIP_LIST"; then
  echo "Zip contains forbidden __MACOSX metadata"
  exit 1
fi

if grep -q '\.DS_Store$' "$ZIP_LIST"; then
  echo "Zip contains .DS_Store files"
  exit 1
fi

if grep -q '\.dSYM/' "$ZIP_LIST"; then
  echo "Zip contains dSYM artifacts"
  exit 1
fi

if grep -q '/\.git/' "$ZIP_LIST"; then
  echo "Zip contains .git content"
  exit 1
fi

if grep -q 'roadmap\.md$' "$ZIP_LIST"; then
  echo "Zip contains local roadmap file"
  exit 1
fi

rm -f "$ZIP_LIST"

echo "Artifact hygiene checks passed for:"
echo "- $APP_PATH"
echo "- $ZIP_PATH"
