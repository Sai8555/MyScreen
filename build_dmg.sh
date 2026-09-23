#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "=================================================="
echo "  Building Gorgeous MyScreen Disk Image (.dmg)    "
echo "=================================================="

BUILD_DIR="$DIR/build"
APP_NAME="MyScreen.app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME"
DMG_NAME="MyScreen.dmg"
DMG_FINAL="$BUILD_DIR/$DMG_NAME"
VOL_NAME="MyScreen"
BG_IMAGE="$DIR/Sources/MyScreen/Resources/dmg_background.png"
ICON_FILE="$DIR/Sources/MyScreen/Resources/AppIcon.icns"
STAGE_DIR="$BUILD_DIR/dmg_stage"

# 1. Ensure latest Release build exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "==> Building Release Application bundle first..."
    ./build_app.sh
fi

# Clean up any previous mounts, files, or staging dirs
hdiutil detach "/Volumes/$VOL_NAME" -force 2>/dev/null || true
rm -rf "$STAGE_DIR"
rm -f "$DMG_FINAL"
mkdir -p "$STAGE_DIR"

# 2. Populate staging folder with MyScreen.app
echo "==> Staging application..."
cp -R "$APP_BUNDLE" "$STAGE_DIR/"

# 3. Use create-dmg for professional layout and styling
if command -v create-dmg &>/dev/null; then
    echo "==> Using create-dmg to generate styled installer..."
    create-dmg \
        --volname "$VOL_NAME" \
        --volicon "$ICON_FILE" \
        --background "$BG_IMAGE" \
        --window-pos 200 120 \
        --window-size 632 424 \
        --text-size 12 \
        --icon-size 110 \
        --icon "MyScreen.app" 146 212 \
        --hide-extension "MyScreen.app" \
        --app-drop-link 486 212 \
        --format UDZO \
        --sandbox-safe \
        --overwrite \
        "$DMG_FINAL" \
        "$STAGE_DIR" || {
            echo "==> create-dmg exited with status $?, falling back to native hdiutil..."
            ln -s /Applications "$STAGE_DIR/Applications"
            hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_FINAL"
        }
else
    echo "==> Using native hdiutil..."
    ln -s /Applications "$STAGE_DIR/Applications"
    hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_FINAL"
fi

rm -rf "$STAGE_DIR"

echo ""
echo "=================================================="
echo "  SUCCESS! MyScreen.dmg Installer Ready!          "
echo "=================================================="
echo "Path: $DMG_FINAL"
if [ -f "$DMG_FINAL" ]; then
    ls -lh "$DMG_FINAL"
fi
