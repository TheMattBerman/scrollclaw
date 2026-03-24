#!/usr/bin/env bash
set -euo pipefail

# Extend an existing video clip by extracting the last frame and using Sora i2v.
# Requires ffmpeg for frame extraction.
#
# Usage:
#   bash extend-clip.sh \
#     --input a-roll-01.mp4 \
#     --prompt-file extension-prompt.txt \
#     --output a-roll-01-extended.mp4 \
#     --seconds 10 \
#     --character-id char_123

INPUT=""
PROMPT_FILE=""
OUTPUT=""
SECONDS_DUR="10"
ASPECT_RATIO="portrait"
CHARACTER_ID=""
PRO="false"
LOG_FILE=""
LABEL="extension"
TIMEOUT=600
TEMP_DIR=""

usage() {
    echo "Usage: extend-clip.sh --input VIDEO --prompt-file FILE --output FILE [options]"
    echo ""
    echo "Options:"
    echo "  --input FILE          Source video to extend (required)"
    echo "  --prompt-file FILE    Description of what happens next (required)"
    echo "  --output FILE         Output extended video path (required)"
    echo "  --seconds N           Extension duration (default: 10)"
    echo "  --aspect-ratio RATIO  9:16, 16:9, or 1:1 (default: 9:16)"
    echo "  --character-id ID     Sora character ID"
    echo "  --pro                 Use Sora 2 Pro"
    echo "  --log-file FILE       Append to output log"
    echo "  --label TEXT          Label for log entry"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input) INPUT="$2"; shift 2 ;;
        --prompt-file) PROMPT_FILE="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --seconds) SECONDS_DUR="$2"; shift 2 ;;
        --aspect-ratio) ASPECT_RATIO="$2"; shift 2 ;;
        --character-id) CHARACTER_ID="$2"; shift 2 ;;
        --pro) PRO="true"; shift ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        --label) LABEL="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$INPUT" ]] && { echo "Error: --input required"; usage; }
[[ -z "$PROMPT_FILE" ]] && { echo "Error: --prompt-file required"; usage; }
[[ -z "$OUTPUT" ]] && { echo "Error: --output required"; usage; }
[[ -z "${REPLICATE_API_TOKEN:-}" ]] && { echo "Error: REPLICATE_API_TOKEN not set"; exit 2; }
command -v ffmpeg &>/dev/null || { echo "Error: ffmpeg required for frame extraction"; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Step 1: Extract last frame from input video
echo "Extracting last frame from $INPUT..."
LAST_FRAME="$TEMP_DIR/last-frame.png"
ffmpeg -sseof -0.1 -i "$INPUT" -frames:v 1 -q:v 2 "$LAST_FRAME" -y 2>/dev/null

if [[ ! -f "$LAST_FRAME" ]]; then
    echo "Error: Failed to extract last frame" >&2
    exit 1
fi
echo "Last frame extracted: $(du -h "$LAST_FRAME" | cut -f1)"

# Step 2: Upload last frame to get a public URL
# Replicate's file upload endpoint
echo "Uploading frame to Replicate..."
UPLOAD_RESPONSE=$(curl -s -X POST "https://api.replicate.com/v1/files" \
    -H "Authorization: Token $REPLICATE_API_TOKEN" \
    -F "content=@$LAST_FRAME" \
    -F "content_type=image/png")

FRAME_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.urls.get // empty')
if [[ -z "$FRAME_URL" ]]; then
    echo "Error uploading frame:" >&2
    echo "$UPLOAD_RESPONSE" | jq . >&2
    exit 1
fi
echo "Frame URL: $FRAME_URL"

# Step 3: Generate extension via Sora i2v
echo "Generating ${SECONDS_DUR}s extension..."

EXTRA_ARGS="--image $FRAME_URL"
[[ -n "$CHARACTER_ID" ]] && EXTRA_ARGS="$EXTRA_ARGS --character-id $CHARACTER_ID"
[[ "$PRO" == "true" ]] && EXTRA_ARGS="$EXTRA_ARGS --pro"
[[ -n "$LOG_FILE" ]] && EXTRA_ARGS="$EXTRA_ARGS --log-file $LOG_FILE"

bash "$SCRIPT_DIR/generate-clip.sh" \
    --prompt-file "$PROMPT_FILE" \
    $EXTRA_ARGS \
    --output "$OUTPUT" \
    --seconds "$SECONDS_DUR" \
    --aspect-ratio "$ASPECT_RATIO" \
    --label "$LABEL" \
    --timeout "$TIMEOUT"

echo ""
echo "Extension complete: $OUTPUT"
echo "To concatenate: ffmpeg -f concat -i list.txt -c copy final.mp4"
