#!/bin/bash
set -euo pipefail

APP_NAME="LofiApp"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR=".build/debug"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"

echo "Building $APP_NAME..."
cd "$SCRIPT_DIR"
swift build 2>&1

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"

# Copy binary
cp "$SCRIPT_DIR/$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"

# Copy app icon
RESOURCES="$CONTENTS/Resources"
mkdir -p "$RESOURCES"
cp "$SCRIPT_DIR/LofiApp/AppIcon.icns" "$RESOURCES/AppIcon.icns"

# Create Info.plist with full app metadata
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.lofiapp.LofiApp</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.music</string>
</dict>
</plist>
PLIST

# Ad-hoc code sign so macOS shows "unidentified developer" instead of "damaged"
echo "Code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done! App bundle at: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
