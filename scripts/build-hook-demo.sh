#!/usr/bin/env bash
set -euo pipefail

# Build a complete Hook + Demo video from components.
# Takes a hook clip (AI face) + demo footage (screen recording or Kling clip)
# and outputs a finished 15s video with captions.
#
# Usage:
#   # With a real screen recording (RECOMMENDED)
#   bash build-hook-demo.sh \
#     --hook hook-face.mp4 \
#     --demo screen-recording.mp4 \
#     --hook-text "when your gym software\Ncannot even handle\Na data migration..." \
#     --output final.mp4
#
#   # With hook duration control
#   bash build-hook-demo.sh \
#     --hook hook-face.mp4 \
#     --demo demo.mp4 \
#     --hook-text "I spent 3 years\Nchasing failed payments" \
#     --hook-duration 4 \
#     --demo-duration 11 \
#     --output final.mp4

HOOK=""
DEMO=""
HOOK_TEXT=""
OUTPUT=""
HOOK_DUR="4"
DEMO_DUR="11"
CAPTION_STYLE="tiktok"
FONT_SIZE="48"
FFMPEG="/usr/bin/ffmpeg"
FFPROBE="/usr/bin/ffprobe"

# Fall back to PATH ffmpeg if system one missing
command -v "$FFMPEG" &>/dev/null || FFMPEG="ffmpeg"
command -v "$FFPROBE" &>/dev/null || FFPROBE="ffprobe"

usage() {
    echo "Build a Hook + Demo UGC video (15s max)"
    echo ""
    echo "Usage: build-hook-demo.sh --hook FILE --demo FILE --hook-text TEXT --output FILE [options]"
    echo ""
    echo "Required:"
    echo "  --hook FILE          Hook face video (AI-generated, 3-5s)"
    echo "  --demo FILE          Demo footage (screen recording RECOMMENDED, or Kling clip)"
    echo "  --hook-text TEXT     Hook text overlay (use \\N for line breaks)"
    echo "  --output FILE        Output video path"
    echo ""
    echo "Options:"
    echo "  --hook-duration N    Trim hook to N seconds (default: 4)"
    echo "  --demo-duration N    Trim demo to N seconds (default: 11)"
    echo "  --font-size N        Caption font size (default: 48)"
    echo "  --style NAME         tiktok or instagram (default: tiktok)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --hook) HOOK="$2"; shift 2 ;;
        --demo) DEMO="$2"; shift 2 ;;
        --hook-text) HOOK_TEXT="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --hook-duration) HOOK_DUR="$2"; shift 2 ;;
        --demo-duration) DEMO_DUR="$2"; shift 2 ;;
        --font-size) FONT_SIZE="$2"; shift 2 ;;
        --style) CAPTION_STYLE="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$HOOK" ]] && { echo "Error: --hook required"; usage; }
[[ -z "$DEMO" ]] && { echo "Error: --demo required"; usage; }
[[ -z "$HOOK_TEXT" ]] && { echo "Error: --hook-text required"; usage; }
[[ -z "$OUTPUT" ]] && { echo "Error: --output required"; usage; }
[[ -f "$HOOK" ]] || { echo "Error: hook file not found: $HOOK"; exit 1; }
[[ -f "$DEMO" ]] || { echo "Error: demo file not found: $DEMO"; exit 1; }
command -v "$FFMPEG" &>/dev/null || { echo "Error: ffmpeg required"; exit 2; }

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

TOTAL_DUR=$(echo "$HOOK_DUR + $DEMO_DUR" | bc)
echo "=== Hook + Demo Builder ==="
echo "Hook: ${HOOK_DUR}s | Demo: ${DEMO_DUR}s | Total: ${TOTAL_DUR}s"
echo "Caption style: $CAPTION_STYLE"
echo ""

# Step 1: Trim and normalize hook
echo "Processing hook..."
$FFMPEG -i "$HOOK" -t "$HOOK_DUR" \
    -vf "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:black" \
    -r 30 -c:v libx264 -preset fast -crf 18 \
    -c:a aac -b:a 128k -ar 44100 \
    "$TEMP_DIR/hook-trimmed.mp4" -y 2>/dev/null

# Step 2: Burn hook text onto hook clip
# Normalize line breaks: accept both \n and \N
LINES=$(echo "$HOOK_TEXT" | sed 's/\\[Nn]/\n/g')
VF=""
IDX=0
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    TFILE="$TEMP_DIR/txt_${IDX}.txt"
    echo "$line" > "$TFILE"
    Y=$((320 + IDX * 65))
    
    if [[ "$CAPTION_STYLE" == "tiktok" ]]; then
        # TikTok style: white text with black box behind it
        PART="drawtext=textfile=${TFILE}:fontsize=${FONT_SIZE}:fontcolor=white:borderw=4:bordercolor=black:box=1:boxcolor=black@0.6:boxborderw=8:x=(w-text_w)/2:y=${Y}:enable='between(t,0,${HOOK_DUR})'"
    else
        # Instagram style: white text with shadow
        PART="drawtext=textfile=${TFILE}:fontsize=${FONT_SIZE}:fontcolor=white:borderw=3:bordercolor=black@0.7:shadowx=2:shadowy=2:shadowcolor=black@0.5:x=(w-text_w)/2:y=${Y}:enable='between(t,0,${HOOK_DUR})'"
    fi
    
    if [[ -z "$VF" ]]; then
        VF="$PART"
    else
        VF="${VF},${PART}"
    fi
    IDX=$((IDX + 1))
done <<< "$LINES"

echo "Burning ${IDX} lines of hook text..."
$FFMPEG -i "$TEMP_DIR/hook-trimmed.mp4" \
    -vf "$VF" \
    -c:v libx264 -preset fast -crf 18 -c:a copy \
    "$TEMP_DIR/hook-captioned.mp4" -y 2>/dev/null

if [[ ! -f "$TEMP_DIR/hook-captioned.mp4" ]]; then
    echo "Warning: text burn failed, using hook without captions"
    cp "$TEMP_DIR/hook-trimmed.mp4" "$TEMP_DIR/hook-captioned.mp4"
fi

# Step 3: Trim and normalize demo
echo "Processing demo..."
$FFMPEG -i "$DEMO" -t "$DEMO_DUR" \
    -vf "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:black" \
    -r 30 -c:v libx264 -preset fast -crf 18 \
    -c:a aac -b:a 128k -ar 44100 \
    "$TEMP_DIR/demo-trimmed.mp4" -y 2>/dev/null

# Step 4: Concatenate hook + demo
echo "Stitching hook → demo..."
cat > "$TEMP_DIR/concat.txt" << EOF
file '$TEMP_DIR/hook-captioned.mp4'
file '$TEMP_DIR/demo-trimmed.mp4'
EOF

$FFMPEG -f concat -safe 0 -i "$TEMP_DIR/concat.txt" -c copy "$OUTPUT" -y 2>/dev/null

FINAL_DUR=$($FFPROBE -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT")
echo ""
echo "=== Done ==="
echo "Output: $OUTPUT"
echo "Duration: ${FINAL_DUR}s"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"
echo "Resolution: $($FFPROBE -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUTPUT")"

if (( $(echo "$FINAL_DUR > 16" | bc -l) )); then
    echo ""
    echo "⚠️  WARNING: Video is over 15s. Trim hook or demo duration for optimal completion rates."
fi
