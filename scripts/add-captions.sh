#!/usr/bin/env bash
set -euo pipefail

# Add native-style captions to a video using ffmpeg + ASS subtitles.
# Produces TikTok/Instagram-style text in the safe zone.
#
# Usage:
#   # From a caption file (one line per caption with timestamps)
#   bash add-captions.sh --video input.mp4 --captions captions.txt --output captioned.mp4
#
#   # With custom style
#   bash add-captions.sh --video input.mp4 --captions captions.txt --output captioned.mp4 --style tiktok
#
#   # With custom font
#   bash add-captions.sh --video input.mp4 --captions captions.txt --output captioned.mp4 --font "/path/to/font.ttf"
#
# Caption file format (one per line):
#   START_TIME|END_TIME|text
#   0:00:00.00|0:00:03.50|so I'm sitting in my car right now
#   0:00:03.50|0:00:07.00|and I know that sounds weird but like
#
# Or use --srt to pass an SRT file instead.

VIDEO=""
CAPTIONS=""
SRT=""
OUTPUT=""
STYLE="tiktok"
FONT=""
FONT_SIZE="42"
MARGIN_V="400"
HIGHLIGHT_WORD=""

usage() {
    echo "Usage: add-captions.sh --video FILE --captions FILE --output FILE [options]"
    echo ""
    echo "Options:"
    echo "  --video FILE       Input video (required)"
    echo "  --captions FILE    Caption file: START|END|text per line (required unless --srt)"
    echo "  --srt FILE         SRT subtitle file (alternative to --captions)"
    echo "  --output FILE      Output video path (required)"
    echo "  --style NAME       tiktok, instagram, or minimal (default: tiktok)"
    echo "  --font PATH        Custom font file path"
    echo "  --font-size N      Font size in pixels (default: 42)"
    echo "  --margin-v N       Vertical margin from bottom (default: 400 = safe zone)"
    echo "  --highlight-word   Highlight one key word per line in accent color"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --video) VIDEO="$2"; shift 2 ;;
        --captions) CAPTIONS="$2"; shift 2 ;;
        --srt) SRT="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --style) STYLE="$2"; shift 2 ;;
        --font) FONT="$2"; shift 2 ;;
        --font-size) FONT_SIZE="$2"; shift 2 ;;
        --margin-v) MARGIN_V="$2"; shift 2 ;;
        --highlight-word) HIGHLIGHT_WORD="true"; shift ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$VIDEO" ]] && { echo "Error: --video required"; usage; }
[[ -z "$CAPTIONS" && -z "$SRT" ]] && { echo "Error: --captions or --srt required"; usage; }
[[ -z "$OUTPUT" ]] && { echo "Error: --output required"; usage; }
[[ -f "$VIDEO" ]] || { echo "Error: video not found: $VIDEO"; exit 1; }
command -v ffmpeg &>/dev/null || { echo "Error: ffmpeg required"; exit 2; }

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
ASS_FILE="$TEMP_DIR/captions.ass"

# Get video resolution
RES_X=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width -of csv=p=0 "$VIDEO")
RES_Y=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$VIDEO")

# Style definitions — platform-native looks
# All styles: white text, bold, centered, in the safe zone
case "$STYLE" in
    tiktok)
        # TikTok: Proxima Nova Bold style, white text with black background box
        FONT_NAME="${FONT:-Arial Bold}"
        PRIMARY_COLOR="&H00FFFFFF"     # White
        OUTLINE_COLOR="&H00000000"     # Black
        BACK_COLOR="&H80000000"        # Semi-transparent black background
        BORDER_STYLE="3"               # Opaque box behind text
        OUTLINE="0"
        SHADOW="0"
        BOLD="1"
        ALIGNMENT="2"                  # Bottom center
        ;;
    instagram)
        # Instagram: Clean white text with subtle drop shadow
        FONT_NAME="${FONT:-Helvetica Neue Bold}"
        PRIMARY_COLOR="&H00FFFFFF"
        OUTLINE_COLOR="&H40000000"
        BACK_COLOR="&H00000000"
        BORDER_STYLE="1"               # Outline + shadow
        OUTLINE="3"
        SHADOW="2"
        BOLD="1"
        ALIGNMENT="2"
        ;;
    minimal)
        # Minimal: White text, thin outline, no background
        FONT_NAME="${FONT:-Arial}"
        PRIMARY_COLOR="&H00FFFFFF"
        OUTLINE_COLOR="&H80000000"
        BACK_COLOR="&H00000000"
        BORDER_STYLE="1"
        OUTLINE="2"
        SHADOW="0"
        BOLD="0"
        ALIGNMENT="2"
        ;;
    *)
        echo "Unknown style: $STYLE (use tiktok, instagram, or minimal)"
        exit 1
        ;;
esac

# Generate ASS header
cat > "$ASS_FILE" << EOF
[Script Info]
Title: UGC Captions
ScriptType: v4.00+
PlayResX: $RES_X
PlayResY: $RES_Y
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Caption,${FONT_NAME},${FONT_SIZE},${PRIMARY_COLOR},&H000000FF,${OUTLINE_COLOR},${BACK_COLOR},${BOLD},0,0,0,100,100,0,0,${BORDER_STYLE},${OUTLINE},${SHADOW},${ALIGNMENT},40,40,${MARGIN_V},1
Style: Highlight,${FONT_NAME},${FONT_SIZE},&H0000DDFF,&H000000FF,${OUTLINE_COLOR},${BACK_COLOR},${BOLD},0,0,0,100,100,0,0,${BORDER_STYLE},${OUTLINE},${SHADOW},${ALIGNMENT},40,40,${MARGIN_V},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
EOF

# Convert captions to ASS events
if [[ -n "$CAPTIONS" ]]; then
    [[ -f "$CAPTIONS" ]] || { echo "Error: captions file not found: $CAPTIONS"; exit 1; }
    
    while IFS='|' read -r START END TEXT; do
        # Skip empty lines and comments
        [[ -z "$TEXT" || "$START" == "#"* ]] && continue
        
        # Trim whitespace
        START=$(echo "$START" | xargs)
        END=$(echo "$END" | xargs)
        TEXT=$(echo "$TEXT" | xargs)
        
        echo "Dialogue: 0,${START},${END},Caption,,0,0,0,,${TEXT}" >> "$ASS_FILE"
    done < "$CAPTIONS"

elif [[ -n "$SRT" ]]; then
    [[ -f "$SRT" ]] || { echo "Error: SRT file not found: $SRT"; exit 1; }
    
    # Convert SRT to ASS events
    # SRT format: number, timestamp --> timestamp, text, blank line
    BLOCK_NUM=""
    BLOCK_START=""
    BLOCK_END=""
    BLOCK_TEXT=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | tr -d '\r')
        
        if [[ "$line" =~ ^[0-9]+$ && -z "$BLOCK_START" ]]; then
            BLOCK_NUM="$line"
        elif [[ "$line" =~ "-->" ]]; then
            # Parse SRT timestamp: 00:00:01,500 --> 00:00:04,000
            BLOCK_START=$(echo "$line" | awk -F' --> ' '{print $1}' | sed 's/,/./')
            BLOCK_END=$(echo "$line" | awk -F' --> ' '{print $2}' | sed 's/,/./')
        elif [[ -z "$line" && -n "$BLOCK_TEXT" ]]; then
            # End of block — write event
            echo "Dialogue: 0,${BLOCK_START},${BLOCK_END},Caption,,0,0,0,,${BLOCK_TEXT}" >> "$ASS_FILE"
            BLOCK_NUM=""
            BLOCK_START=""
            BLOCK_END=""
            BLOCK_TEXT=""
        elif [[ -n "$BLOCK_START" ]]; then
            if [[ -n "$BLOCK_TEXT" ]]; then
                BLOCK_TEXT="$BLOCK_TEXT\\N$line"
            else
                BLOCK_TEXT="$line"
            fi
        fi
    done < "$SRT"
    
    # Handle last block if file doesn't end with blank line
    if [[ -n "$BLOCK_TEXT" ]]; then
        echo "Dialogue: 0,${BLOCK_START},${BLOCK_END},Caption,,0,0,0,,${BLOCK_TEXT}" >> "$ASS_FILE"
    fi
fi

CAPTION_COUNT=$(grep -c "^Dialogue:" "$ASS_FILE")
echo "=== Caption Burner ==="
echo "Video: $VIDEO"
echo "Style: $STYLE"
echo "Captions: $CAPTION_COUNT lines"
echo "Font size: ${FONT_SIZE}px"
echo "Safe zone margin: ${MARGIN_V}px from bottom"
echo ""

# Burn captions onto video
echo "Burning captions..."
ffmpeg -i "$VIDEO" \
    -vf "ass=$ASS_FILE" \
    -c:v libx264 -preset fast -crf 18 \
    -c:a copy \
    "$OUTPUT" -y 2>/dev/null

echo "Done: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
echo "Resolution: $(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUTPUT")"
