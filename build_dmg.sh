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
BG_IMAGE="$DIR/Sources/MyScreen/Resources/dmg_background.tiff"
ICON_FILE="$DIR/Sources/MyScreen/Resources/AppIcon.icns"
STAGE_DIR="$BUILD_DIR/dmg_stage"

# Ensure HiDPI TIFF exists
if [ ! -f "$BG_IMAGE" ]; then
    echo "==> Creating HiDPI background TIFF..."
    sips -z 424 632 -s dpiWidth 72.0 -s dpiHeight 72.0 "$DIR/Sources/MyScreen/Resources/dmg_background.png" --out "$DIR/Sources/MyScreen/Resources/dmg_background_1x.png"
    tiffutil -cathidpicheck "$DIR/Sources/MyScreen/Resources/dmg_background_1x.png" "$DIR/Sources/MyScreen/Resources/dmg_background.png" -out "$BG_IMAGE"
fi

# 1. Ensure latest Release build exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "==> Building Release Application bundle first..."
    ./build_app.sh
fi

# Clean up any previous mounts, files, or staging dirs
hdiutil detach "/Volumes/$VOL_NAME" -force 2>/dev/null || true
rm -rf "$STAGE_DIR"
rm -f "$DMG_FINAL"
rm -f "$BUILD_DIR"/rw.*.dmg
mkdir -p "$STAGE_DIR"

# 2. Populate staging folder with MyScreen.app
echo "==> Staging MyScreen.app..."
cp -R "$APP_BUNDLE" "$STAGE_DIR/"

DMGBUILD_BIN="$DIR/.build/dmg_venv/bin/dmgbuild"

if [ -f "$DMGBUILD_BIN" ]; then
    echo "==> Building pixel-perfect DMG with dmgbuild (deterministic DS_Store)..."
    "$DMGBUILD_BIN" -s "$DIR/dmg_settings.py" "$VOL_NAME" "$DMG_FINAL"
elif command -v create-dmg &>/dev/null; then
    echo "==> Using create-dmg to generate styled installer..."
    create-dmg \
        --volname "$VOL_NAME" \
        --volicon "$ICON_FILE" \
        --background "$BG_IMAGE" \
        --window-pos 200 120 \
        --window-size 632 424 \
        --text-size 12 \
        --icon-size 90 \
        --icon "MyScreen.app" 180 212 \
        --hide-extension "MyScreen.app" \
        --app-drop-link 452 212 \
        --format UDZO \
        --overwrite \
        "$DMG_FINAL" \
        "$STAGE_DIR" || {
            echo "==> AppleScript automation restricted. Building via --skip-jenkins..."
            rm -f "$BUILD_DIR"/rw.*.dmg
            create-dmg \
                --volname "$VOL_NAME" \
                --volicon "$ICON_FILE" \
                --background "$BG_IMAGE" \
                --window-pos 200 120 \
                --window-size 632 424 \
                --text-size 12 \
                --icon-size 90 \
                --icon "MyScreen.app" 180 212 \
                --hide-extension "MyScreen.app" \
                --app-drop-link 452 212 \
                --skip-jenkins \
                --format UDZO \
                --overwrite \
                "$DMG_FINAL" \
                "$STAGE_DIR"
        }
else
    echo "==> create-dmg not found. Please install via: brew install create-dmg"
    exit 1
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
