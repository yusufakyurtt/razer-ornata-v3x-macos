#!/bin/bash
set -e

echo "=== Creating Razer Control macOS DMG Installer ==="

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Razer Control"
VERSION="1.0.0"
DMG_NAME="Razer-Control-v1.0.0-macOS-x86_64.dmg"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found at $APP_BUNDLE. Running build script first..."
    ./scripts/build_release_app.sh
fi

TMP_DIR="$(mktemp -d /tmp/razer_control_dmg.XXXXXX)"
echo "1. Staging DMG content in $TMP_DIR..."

# Copy App bundle
cp -R "$APP_BUNDLE" "$TMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TMP_DIR/Applications"

# Copy Icon if present
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$TMP_DIR/.VolumeIcon.icns" || true
fi

echo "2. Building compressed UDZO DMG..."
rm -f "$DMG_PATH"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$TMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$TMP_DIR"

echo "3. Verifying DMG..."
hdiutil verify "$DMG_PATH"
ls -lh "$DMG_PATH"

echo "=== DMG CREATED SUCCESSFULLY ==="
echo "DMG File: $DMG_PATH"
