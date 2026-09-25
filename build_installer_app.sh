#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "=================================================="
echo "  Building Native Live Video Installer App        "
echo "=================================================="

BUILD_DIR="$DIR/build"
INSTALLER_NAME="Install MyScreen.app"
INSTALLER_BUNDLE="$BUILD_DIR/$INSTALLER_NAME"
CONTENTS="$INSTALLER_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$BUILD_DIR"
rm -rf "$INSTALLER_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"
mkdir -p "$DIR/.build/cache"

echo "==> Compiling Swift native installer binary..."
swiftc \
    -module-cache-path "$DIR/.build/cache" \
    -O \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    Sources/MyScreenInstaller/main.swift \
    -o "$MACOS/Install MyScreen"

echo "==> Creating Info.plist..."
cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Install MyScreen</string>
    <key>CFBundleIdentifier</key>
    <string>com.myscreen.installer</string>
    <key>CFBundleName</key>
    <string>Install MyScreen</string>
    <key>CFBundleDisplayName</key>
    <string>Install MyScreen</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Copying assets, scenery image, and application bundle..."
cp "Sources/MyScreen/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
cp "Sources/MyScreen/Resources/installer_scenery.png" "$RESOURCES/installer_scenery.png"
if [ -d "$BUILD_DIR/MyScreen.app" ]; then
    echo "==> Bundling MyScreen.app into installer..."
    cp -R "$BUILD_DIR/MyScreen.app" "$RESOURCES/MyScreen.app"
fi

# Set executable permissions
chmod +x "$MACOS/Install MyScreen"

echo "=================================================="
echo "  SUCCESS! Live Video Installer Built!            "
echo "=================================================="
echo "Path: $INSTALLER_BUNDLE"
ls -lh "$INSTALLER_BUNDLE/Contents/MacOS"
