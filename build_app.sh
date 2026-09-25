#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "==> Building MyScreen (Release mode)..."
swift build -c release

APP_NAME="MyScreen.app"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Packaging $APP_NAME bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy custom MyScreen icon
if [ -f "$DIR/Sources/MyScreen/Resources/AppIcon.icns" ]; then
    cp "$DIR/Sources/MyScreen/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Copy catalog.json if available
if [ -f "$DIR/Sources/MyScreen/Resources/catalog.json" ]; then
    cp "$DIR/Sources/MyScreen/Resources/catalog.json" "$RESOURCES_DIR/catalog.json"
fi

# Copy binary
cp "$DIR/.build/release/MyScreen" "$MACOS_DIR/MyScreen"
chmod +x "$MACOS_DIR/MyScreen"

# Write Info.plist
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>MyScreen</string>
    <key>CFBundleExecutable</key>
    <string>MyScreen</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.myscreen.wallpaper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MyScreen</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>NSSupportsAppNap</key>
    <false/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

# PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Ad-hoc code signing
if command -v codesign &>/dev/null; then
    echo "==> Applying ad-hoc codesign..."
    codesign --force --deep --sign - "$APP_BUNDLE" || true
fi

# Prevent macOS Spotlight from indexing the build directory as a second application
touch "$BUILD_DIR/.metadata_never_index"

# Create distribution zip
echo "==> Creating distribution zip..."
(cd "$BUILD_DIR" && rm -f MyScreen.zip && zip -r -q -y MyScreen.zip "$APP_NAME")

if [ "$1" == "--install" ]; then
    echo "==> Terminating previous instance if running..."
    killall MyScreen 2>/dev/null || true
    sleep 0.5

    echo "==> Installing into /Applications/MyScreen.app..."
    rm -rf "/Applications/MyScreen.app"
    cp -R "$APP_BUNDLE" "/Applications/"
    
    # Remove build folder app bundle so macOS only sees /Applications/MyScreen.app
    rm -rf "$APP_BUNDLE"
    
    echo "==> MyScreen.app installed to /Applications successfully!"
    echo "==> Starting newly installed /Applications/MyScreen.app..."
    open "/Applications/MyScreen.app"
elif [ "$1" == "--dmg" ]; then
    "$DIR/build_dmg.sh"
else
    echo "==> Success! MyScreen bundle created at: $APP_BUNDLE"
    echo "==> Run './build_dmg.sh' or './build_app.sh --dmg' to create a .dmg disk image installer."
fi
