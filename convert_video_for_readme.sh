#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# 1. Determine input video: provided as argument OR auto-find latest screen recording
if [ -n "$1" ] && [ -f "$1" ]; then
    INPUT_VIDEO="$1"
else
    # Find the most recently recorded video in ~/Downloads or ~/Desktop
    LATEST_VIDEO=$(ls -t "$HOME/Downloads"/*.mov "$HOME/Downloads"/*.mp4 "$HOME/Desktop"/*.mov "$HOME/Desktop"/*.mp4 2>/dev/null | head -n 1)
    if [ -n "$LATEST_VIDEO" ] && [ -f "$LATEST_VIDEO" ]; then
        INPUT_VIDEO="$LATEST_VIDEO"
    else
        INPUT_VIDEO="$HOME/Downloads/Screen Recording 2026-09-23 at 10.58.30 AM.mov"
    fi
fi

if [ ! -f "$INPUT_VIDEO" ]; then
    echo "Error: Video file not found."
    echo "Usage: ./convert_video_for_readme.sh [path_to_new_video.mov]"
    exit 1
fi

echo "=========================================================="
echo "  Converting Updated Video for GitHub README              "
echo "=========================================================="
echo "Detected Input Video: $INPUT_VIDEO"

mkdir -p "$DIR/docs/assets"

OUTPUT_GIF="$DIR/docs/assets/demo.gif"
OUTPUT_MP4="$DIR/docs/assets/demo.mp4"

# 2. Compress to optimized web MP4
echo "==> Converting & compressing video..."
/opt/homebrew/bin/ffmpeg -y -i "$INPUT_VIDEO" \
    -vf "scale=1280:-2" \
    -c:v libx264 -preset slow -crf 22 -pix_fmt yuv420p \
    -c:a aac -b:a 128k -movflags +faststart \
    "$OUTPUT_MP4"

# 3. Generate high-quality looping GIF for GitHub auto-play
echo "==> Creating high-quality looping GIF for GitHub README..."
PALETTE="/tmp/myscreen_palette.png"
/opt/homebrew/bin/ffmpeg -y -i "$OUTPUT_MP4" \
    -vf "fps=15,scale=900:-1:flags=lanczos,palettegen=stats_mode=diff" \
    "$PALETTE"

/opt/homebrew/bin/ffmpeg -y -i "$OUTPUT_MP4" -i "$PALETTE" \
    -lavfi "fps=15,scale=900:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=3" \
    "$OUTPUT_GIF"

rm -f "$PALETTE"

echo ""
echo "=========================================================="
echo "  SUCCESS! Updated Demo Files Ready!                      "
echo "=========================================================="
echo "GIF: $OUTPUT_GIF ($(ls -lh "$OUTPUT_GIF" | awk '{print $5}'))"
echo "MP4: $OUTPUT_MP4 ($(ls -lh "$OUTPUT_MP4" | awk '{print $5}'))"
echo ""
echo "To push this updated video to your GitHub repo, run:"
echo ""
echo "    git add docs/assets/demo.gif docs/assets/demo.mp4 README.md"
echo "    git commit -m \"docs: update live demo recording\""
echo "    git push origin main"
echo ""
