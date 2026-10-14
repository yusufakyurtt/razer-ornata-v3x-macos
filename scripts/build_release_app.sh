#!/bin/bash
set -e

echo "=== Building Razer Control for Intel macOS (x86_64) ==="

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Razer Control"
BUNDLE_ID="app.momentoid.razercontrol"
VERSION="1.0.0"
BUILD_NUM="1"

BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "1. Compiling Release Binary for x86_64..."
swift build -c release --triple x86_64-apple-macosx

SPM_BIN_DIR="$PROJECT_DIR/.build/x86_64-apple-macosx/release"
EXEC_PATH="$SPM_BIN_DIR/RazerControl"

if [ ! -f "$EXEC_PATH" ]; then
    echo "ERROR: Release binary not found at $EXEC_PATH"
    exit 1
fi

echo "2. Creating .app Bundle Hierarchy..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "3. Installing Executable..."
cp "$EXEC_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

echo "4. Installing Resources..."
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Copy SPM Resource Bundle if present
for b in "$SPM_BIN_DIR"/*.bundle; do
    if [ -d "$b" ]; then
        cp -r "$b" "$RESOURCES_DIR/"
    fi
done

# Copy Localizations
mkdir -p "$RESOURCES_DIR/en.lproj"
mkdir -p "$RESOURCES_DIR/tr.lproj"
cp "$PROJECT_DIR/Sources/RazerControlKit/Resources/en.lproj/Localizable.strings" "$RESOURCES_DIR/en.lproj/"
cp "$PROJECT_DIR/Sources/RazerControlKit/Resources/tr.lproj/Localizable.strings" "$RESOURCES_DIR/tr.lproj/"

echo "5. Generating Info.plist..."
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUM</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Razer Control uses Accessibility permissions to enable custom key remappings and macro playback.</string>
    <key>NSInputMonitoringUsageDescription</key>
    <string>Razer Control requires Input Monitoring to detect keyboard events when running in the background.</string>
</dict>
</plist>
EOF

echo "6. Writing PkgInfo..."
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "7. Signing Bundle (Ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "8. Verifying Architecture and Signature..."
echo "--- File Verification ---"
file "$MACOS_DIR/$APP_NAME"
echo "--- Lipo Architecture ---"
lipo -info "$MACOS_DIR/$APP_NAME"
echo "--- Code Signature ---"
codesign -vvv "$APP_BUNDLE"

echo ""
echo "=== BUILD SUCCESSFUL ==="
echo "Application bundle created at: $APP_BUNDLE"
