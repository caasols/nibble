#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CHECK_SCRIPT="$ROOT_DIR/scripts/release/check-artifact-hygiene.sh"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

APP_DIR="$TMP_DIR/Nibble.app"
ZIP_OK="$TMP_DIR/Nibble-ok.zip"
ZIP_BAD="$TMP_DIR/Nibble-bad.zip"

mkdir -p "$APP_DIR/Contents/MacOS"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.caasols.nibble</string>
</dict>
</plist>
PLIST

cat > "$APP_DIR/Contents/MacOS/Nibble" <<'BIN'
#!/bin/bash
exit 0
BIN
chmod +x "$APP_DIR/Contents/MacOS/Nibble"

mkdir -p "$TMP_DIR/ok/Nibble.app"
cp -R "$APP_DIR/" "$TMP_DIR/ok/Nibble.app"
(
  cd "$TMP_DIR/ok"
  zip -r "$ZIP_OK" Nibble.app >/dev/null
)

mkdir -p "$TMP_DIR/bad/Nibble.app/__MACOSX"
cp -R "$APP_DIR/" "$TMP_DIR/bad/Nibble.app"
touch "$TMP_DIR/bad/Nibble.app/.DS_Store"
(
  cd "$TMP_DIR/bad"
  zip -r "$ZIP_BAD" Nibble.app >/dev/null
)

echo "Expecting failure on unsigned local fixture..."
set +e
"$CHECK_SCRIPT" \
  --app-path "$APP_DIR" \
  --zip-path "$ZIP_OK" \
  --expected-bundle-id "com.caasols.nibble" >/dev/null 2>&1
unsigned_exit=$?
set -e

if [[ "$unsigned_exit" -eq 0 ]]; then
  echo "Expected unsigned fixture to fail, but it passed"
  exit 1
fi

echo "Expecting metadata check failure with --skip-signing-check..."
set +e
SKIP_SIGNING_CHECK=1 "$CHECK_SCRIPT" \
  --app-path "$APP_DIR" \
  --zip-path "$ZIP_BAD" \
  --expected-bundle-id "com.caasols.nibble" >/dev/null 2>&1
bad_zip_exit=$?
set -e

if [[ "$bad_zip_exit" -eq 0 ]]; then
  echo "Expected bad zip fixture to fail, but it passed"
  exit 1
fi

echo "Release hygiene script tests passed"
