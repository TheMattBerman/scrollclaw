#!/usr/bin/env bash
set -euo pipefail

# Stitch multiple video clips into one final video.
# Normalizes resolution, frame rate, and codec across all clips.
# Optionally replaces audio with a separate voice track.
#
# Usage:
#   # Basic stitch (keeps original audio)
#   bash stitch-video.sh --clips clip1.mp4 clip2.mp4 clip3.mp4 --output final.mp4
#
#   # Stitch with replacement voice track
#   bash stitch-video.sh --clips clip1.mp4 clip2.mp4 --output final.mp4 --voice voice.mp3
#
#   # Stitch with voice + ambient layer
#   bash stitch-video.sh --clips clip1.mp4 clip2.mp4 --output final.mp4 --voice voice.mp3 --ambient ambient.mp3 --ambient-vol 0.2

CLIPS=()
OUTPUT=""
VOICE=""
AMBIENT=""
AMBIENT_VOL="0.2"
WIDTH="720"
HEIGHT="1280"
FPS="30"
CRF="18"

usage() {
    echo "Usage: stitch-video.sh --clips FILE [FILE...] --output FILE [options]"
    echo ""
    echo "Options:"
    echo "  --clips FILE [FILE...]   Video clips in order (required)"
    echo "  --output FILE            Output file path (required)"
    echo "  --voice FILE             Replace all audio with this voice track"
    echo "  --ambient FILE           Layer this ambient audio underneath the voice"
    echo "  --ambient-vol FLOAT      Ambient volume level (default: 0.2)"
    echo "  --width N                Target width (default: 720)"
    echo "  --height N               Target height (default: 1280)"
    echo "  --fps N                  Target frame rate (default: 30)"
    exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clips)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                CLIPS+=("$1")
                shift
            done
            ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --voice) VOICE="$2"; shift 2 ;;
        --ambient) AMBIENT="$2"; shift 2 ;;
        --ambient-vol) AMBIENT_VOL="$2"; shift 2 ;;
        --width) WIDTH="$2"; shift 2 ;;
        --height) HEIGHT="$2"; shift 2 ;;
        --fps) FPS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ ${#CLIPS[@]} -eq 0 ]] && { echo "Error: --clips required"; usage; }
[[ -z "$OUTPUT" ]] && { echo "Error: --output required"; usage; }
command -v ffmpeg &>/dev/null || { echo "Error: ffmpeg required"; exit 2; }
command -v ffprobe &>/dev/null || { echo "Error: ffprobe required"; exit 2; }

# Verify all input clips exist
for clip in "${CLIPS[@]}"; do
    [[ -f "$clip" ]] || { echo "Error: clip not found: $clip"; exit 1; }
done

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "=== Video Stitcher ==="
echo "Clips: ${#CLIPS[@]}"
echo "Target: ${WIDTH}x${HEIGHT} @ ${FPS}fps"
echo ""

# Step 1: Normalize all clips to same resolution, fps, codec
echo "Normalizing clips..."
CONCAT_FILE="$TEMP_DIR/concat.txt"
for i in "${!CLIPS[@]}"; do
    SRC="${CLIPS[$i]}"
    NORM="$TEMP_DIR/clip_$(printf '%02d' $i).mp4"
    
    # Scale to target, pad if needed to maintain aspect ratio
    ffmpeg -i "$SRC" \
        -vf "scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease,pad=${WIDTH}:${HEIGHT}:(ow-iw)/2:(oh-ih)/2:black" \
        -r "$FPS" \
        -c:v libx264 -preset fast -crf "$CRF" \
        -c:a aac -b:a 128k -ar 44100 \
        "$NORM" -y 2>/dev/null
    
    echo "  $(basename "$SRC") → $(du -h "$NORM" | cut -f1)"
    echo "file '$NORM'" >> "$CONCAT_FILE"
done

# Step 2: Concatenate video
echo ""
echo "Stitching..."
STITCHED="$TEMP_DIR/stitched.mp4"
ffmpeg -f concat -safe 0 -i "$CONCAT_FILE" -c copy "$STITCHED" -y 2>/dev/null

DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$STITCHED")
echo "Stitched: $(du -h "$STITCHED" | cut -f1), ${DUR}s"

# Step 3: Audio handling
if [[ -n "$VOICE" ]]; then
    echo ""
    echo "Replacing audio with voice track..."
    
    if [[ -n "$AMBIENT" ]]; then
        # Mix voice + ambient
        echo "Mixing voice + ambient (vol: $AMBIENT_VOL)..."
        ffmpeg -i "$STITCHED" -i "$VOICE" -i "$AMBIENT" \
            -filter_complex "[1:a]apad[voice];[2:a]volume=${AMBIENT_VOL},apad[amb];[voice][amb]amix=inputs=2:duration=shortest[aout]" \
            -map 0:v -map "[aout]" \
            -c:v copy -c:a aac -b:a 192k \
            -shortest \
            "$OUTPUT" -y 2>/dev/null
    else
        # Voice only, strip original audio
        ffmpeg -i "$STITCHED" -i "$VOICE" \
            -map 0:v -map 1:a \
            -c:v copy -c:a aac -b:a 192k \
            -shortest \
            "$OUTPUT" -y 2>/dev/null
    fi
else
    # Keep original audio
    cp "$STITCHED" "$OUTPUT"
fi

FINAL_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT")
echo ""
echo "=== Done ==="
echo "Output: $OUTPUT"
echo "Duration: ${FINAL_DUR}s"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"
echo "Resolution: $(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUTPUT")"
