#!/usr/bin/env bash
# qa-check.sh — Post-stitch QA for ScrollClaw videos
# Run after stitching: bash scripts/qa-check.sh <video-file> [--timestamps t1,t2,t3]
# Exit 0 = passes basic QA. Exit 1 = issues found.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS="✅"
FAIL="❌"
WARN="⚠️ "
INFO="ℹ️ "

FAILURES=0
WARNINGS=0

pass()  { echo "  ${PASS} $1"; }
fail()  { echo "  ${FAIL} $1"; FAILURES=$((FAILURES + 1)); }
warn()  { echo "  ${WARN} $1"; WARNINGS=$((WARNINGS + 1)); }
info()  { echo "  ${INFO} $1"; }
header(){ echo; echo "━━━ $1 ━━━"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <video-file> [options]

Post-stitch QA — extracts thumbnails, checks codec compatibility, reports stats.

Arguments:
  video-file          Path to the video to QA

Options:
  --timestamps T1,T2  Comma-separated timestamps (seconds) for thumbnail extraction
  --output-dir DIR    Where to save QA thumbnails (default: same dir as video)
  --scenes N          Number of evenly-spaced thumbnails if no timestamps given (default: 5)
  -h, --help          Show this help message

Example:
  bash scripts/qa-check.sh workspace/campaigns/ridge/clips/final-v1.mp4
  bash scripts/qa-check.sh final.mp4 --timestamps 0.5,4.0,8.0,12.0 --output-dir qa/
EOF
  exit 0
}

# ─────────────────────────────────────────────
# Args
# ─────────────────────────────────────────────

VIDEO=""
TIMESTAMPS=""
OUTPUT_DIR=""
SCENES=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --timestamps) TIMESTAMPS="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --scenes) SCENES="$2"; shift 2 ;;
    *) VIDEO="$1"; shift ;;
  esac
done

if [[ -z "$VIDEO" ]]; then
  echo "Error: video file required"
  echo "Usage: $(basename "$0") <video-file>"
  exit 1
fi

if [[ ! -f "$VIDEO" ]]; then
  echo "Error: file not found: $VIDEO"
  exit 1
fi

VIDEO_DIR="$(dirname "$VIDEO")"
VIDEO_BASE="$(basename "${VIDEO%.*}")"
OUTPUT_DIR="${OUTPUT_DIR:-$VIDEO_DIR/qa}"
mkdir -p "$OUTPUT_DIR"

# Find ffprobe
FFPROBE=""
for cmd in /usr/bin/ffprobe ffprobe; do
  if command -v "$cmd" &>/dev/null; then
    FFPROBE="$cmd"
    break
  fi
done

FFMPEG=""
for cmd in /usr/bin/ffmpeg ffmpeg; do
  if command -v "$cmd" &>/dev/null; then
    FFMPEG="$cmd"
    break
  fi
done

if [[ -z "$FFPROBE" ]] || [[ -z "$FFMPEG" ]]; then
  echo "Error: ffmpeg/ffprobe not found"
  exit 1
fi

echo "🔍 ScrollClaw QA Check"
echo "   Video: $VIDEO"
echo "   Output: $OUTPUT_DIR"

# ─────────────────────────────────────────────
# 1. Video stats
# ─────────────────────────────────────────────

header "Video Stats"

# Duration
DURATION=$($FFPROBE -v quiet -show_entries format=duration -of csv=p=0 "$VIDEO" 2>/dev/null || echo "0")
DURATION_INT="${DURATION%%.*}"
info "Duration: ${DURATION}s"

# Resolution
RESOLUTION=$($FFPROBE -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$VIDEO" 2>/dev/null || echo "unknown")
WIDTH=$(echo "$RESOLUTION" | cut -d',' -f1)
HEIGHT=$(echo "$RESOLUTION" | cut -d',' -f2)
info "Resolution: ${WIDTH}x${HEIGHT}"

# File size
FILE_SIZE=$(stat -c%s "$VIDEO" 2>/dev/null || stat -f%z "$VIDEO" 2>/dev/null || echo "0")
FILE_SIZE_MB=$(echo "scale=1; $FILE_SIZE / 1048576" | bc 2>/dev/null || echo "?")
info "File size: ${FILE_SIZE_MB}MB"

# Frame rate
FPS=$($FFPROBE -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$VIDEO" 2>/dev/null || echo "unknown")
info "Frame rate: ${FPS}"

# ─────────────────────────────────────────────
# 2. Codec compatibility
# ─────────────────────────────────────────────

header "Codec Compatibility"

# Video codec
VCODEC=$($FFPROBE -v quiet -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$VIDEO" 2>/dev/null || echo "unknown")
if [[ "$VCODEC" == "h264" ]]; then
  pass "Video codec: h264"
else
  warn "Video codec: $VCODEC (h264 recommended for compatibility)"
fi

# Pixel format
PIX_FMT=$($FFPROBE -v quiet -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$VIDEO" 2>/dev/null || echo "unknown")
if [[ "$PIX_FMT" == "yuv420p" ]]; then
  pass "Pixel format: yuv420p"
else
  fail "Pixel format: $PIX_FMT (MUST be yuv420p for Telegram/web compatibility)"
  echo "     Fix: re-encode with -pix_fmt yuv420p"
fi

# Profile
PROFILE=$($FFPROBE -v quiet -select_streams v:0 -show_entries stream=profile -of csv=p=0 "$VIDEO" 2>/dev/null || echo "unknown")
PROFILE_LOWER=$(echo "$PROFILE" | tr '[:upper:]' '[:lower:]')
if [[ "$PROFILE_LOWER" == "main" ]] || [[ "$PROFILE_LOWER" == "baseline" ]] || [[ "$PROFILE_LOWER" == "high" ]]; then
  pass "Profile: $PROFILE"
else
  fail "Profile: $PROFILE (use -profile:v main for broad compatibility)"
fi

# Audio codec
ACODEC=$($FFPROBE -v quiet -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$VIDEO" 2>/dev/null || echo "none")
if [[ "$ACODEC" == "aac" ]]; then
  pass "Audio codec: aac"
elif [[ "$ACODEC" == "none" ]] || [[ -z "$ACODEC" ]]; then
  info "No audio stream"
else
  warn "Audio codec: $ACODEC (aac recommended)"
fi

# movflags faststart check
MOOV_AT_START=$($FFPROBE -v trace "$VIDEO" 2>&1 | grep -c "type:'moov'" || true)
# Heuristic: if moov atom appears early in the trace output, faststart is likely set
info "Tip: ensure -movflags +faststart was used for web streaming"

# ─────────────────────────────────────────────
# 3. Thumbnail extraction
# ─────────────────────────────────────────────

header "Thumbnail Extraction (for content drift review)"

# Build timestamp list
TS_LIST=()
if [[ -n "$TIMESTAMPS" ]]; then
  IFS=',' read -ra TS_LIST <<< "$TIMESTAMPS"
else
  # Evenly space across duration
  if [[ "$DURATION_INT" -gt 0 ]] && [[ "$SCENES" -gt 0 ]]; then
    INTERVAL=$(echo "scale=2; $DURATION / $SCENES" | bc 2>/dev/null || echo "1")
    for i in $(seq 0 $((SCENES - 1))); do
      TS=$(echo "scale=2; $INTERVAL * $i + $INTERVAL / 2" | bc 2>/dev/null || echo "$i")
      TS_LIST+=("$TS")
    done
  fi
fi

THUMB_COUNT=0
for ts in "${TS_LIST[@]}"; do
  OUTFILE="$OUTPUT_DIR/${VIDEO_BASE}-qa-t${ts}s.jpg"
  if $FFMPEG -y -ss "$ts" -i "$VIDEO" -frames:v 1 -q:v 2 "$OUTFILE" 2>/dev/null; then
    pass "Extracted frame at ${ts}s → $(basename "$OUTFILE")"
    THUMB_COUNT=$((THUMB_COUNT + 1))
  else
    warn "Failed to extract frame at ${ts}s"
  fi
done

if [[ $THUMB_COUNT -gt 0 ]]; then
  info "Saved $THUMB_COUNT thumbnails to $OUTPUT_DIR/"
  info "Review these for content drift (wrong person, artifacts, scene changes)"
else
  warn "No thumbnails extracted"
fi

# ─────────────────────────────────────────────
# 4. Quick sanity checks
# ─────────────────────────────────────────────

header "Sanity Checks"

# Duration sanity
if [[ "$DURATION_INT" -lt 3 ]]; then
  warn "Very short video (${DURATION}s) — is this intentional?"
elif [[ "$DURATION_INT" -gt 60 ]]; then
  warn "Long video (${DURATION}s) — most UGC is under 30s"
else
  pass "Duration in typical UGC range"
fi

# Resolution check (should be 9:16 vertical)
if [[ -n "$WIDTH" ]] && [[ -n "$HEIGHT" ]] && [[ "$WIDTH" =~ ^[0-9]+$ ]] && [[ "$HEIGHT" =~ ^[0-9]+$ ]]; then
  if [[ "$HEIGHT" -gt "$WIDTH" ]]; then
    pass "Vertical format (${WIDTH}x${HEIGHT})"
  else
    warn "Not vertical format (${WIDTH}x${HEIGHT}) — UGC is typically 9:16"
  fi
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $FAILURES -eq 0 ]]; then
  echo "  ✅ QA PASSED ($WARNINGS warning(s))"
  echo "  Review thumbnails in $OUTPUT_DIR/ for content drift."
else
  echo "  ❌ QA FAILED — $FAILURES issue(s), $WARNINGS warning(s)"
  echo "  Fix codec/format issues before delivery."
  echo
  echo "  Compatible encoding defaults:"
  echo "  -c:v libx264 -profile:v main -pix_fmt yuv420p -crf 23 -preset medium -movflags +faststart -c:a aac -b:a 128k -ar 44100"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $FAILURES
