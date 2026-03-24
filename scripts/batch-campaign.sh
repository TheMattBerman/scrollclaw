#!/usr/bin/env bash
set -euo pipefail

# Batch generate UGC campaign: every combination of creator × format.
#
# Expects a workspace directory with:
#   creators/          - creator profile .md files
#   brief.md           - campaign brief
#   prompts/           - will be created with generated prompts
#   clips/             - will be created with generated videos
#
# Usage:
#   bash batch-campaign.sh \
#     --workspace campaigns/skincare-launch \
#     --creators creators/ \
#     --formats "talking-head,unboxing,pov-demo" \
#     --seconds 8 \
#     --dual-output

WORKSPACE=""
CREATORS_DIR=""
FORMATS=""
SECONDS_DUR="8"
DUAL_OUTPUT=""
PRO=""
CHARACTER_IDS_FILE=""
DRY_RUN="false"

usage() {
    echo "Usage: batch-campaign.sh --workspace DIR --creators DIR --formats LIST [options]"
    echo ""
    echo "Options:"
    echo "  --workspace DIR       Campaign workspace directory (required)"
    echo "  --creators DIR        Directory with creator .md profiles (required)"
    echo "  --formats LIST        Comma-separated format names (required)"
    echo "  --seconds N           Duration per clip (default: 8)"
    echo "  --dual-output         Generate both 16:9 and 9:16"
    echo "  --pro                 Use Sora 2 Pro"
    echo "  --character-ids FILE  JSON file mapping creator names to character_ids"
    echo "  --dry-run             Show what would be generated without running"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workspace) WORKSPACE="$2"; shift 2 ;;
        --creators) CREATORS_DIR="$2"; shift 2 ;;
        --formats) FORMATS="$2"; shift 2 ;;
        --seconds) SECONDS_DUR="$2"; shift 2 ;;
        --dual-output) DUAL_OUTPUT="--dual-output"; shift ;;
        --pro) PRO="--pro"; shift ;;
        --character-ids) CHARACTER_IDS_FILE="$2"; shift 2 ;;
        --dry-run) DRY_RUN="true"; shift ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$WORKSPACE" ]] && { echo "Error: --workspace required"; usage; }
[[ -z "$CREATORS_DIR" ]] && { echo "Error: --creators required"; usage; }
[[ -z "$FORMATS" ]] && { echo "Error: --formats required"; usage; }
[[ -z "${REPLICATE_API_TOKEN:-}" ]] && { echo "Error: REPLICATE_API_TOKEN not set"; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Setup workspace directories
mkdir -p "$WORKSPACE/prompts" "$WORKSPACE/clips" "$WORKSPACE/frames"

# Parse formats
IFS=',' read -ra FORMAT_LIST <<< "$FORMATS"

# Find creators
CREATOR_FILES=("$CREATORS_DIR"/creator-*.md)
if [[ ${#CREATOR_FILES[@]} -eq 0 ]]; then
    echo "Error: No creator-*.md files found in $CREATORS_DIR" >&2
    exit 1
fi

LOG_FILE="$WORKSPACE/output-log.md"
TOTAL=0
SUCCEEDED=0
FAILED=0

echo "=== UGC Batch Campaign ==="
echo "Workspace: $WORKSPACE"
echo "Creators: ${#CREATOR_FILES[@]}"
echo "Formats: ${#FORMAT_LIST[@]} (${FORMATS})"
echo "Combinations: $(( ${#CREATOR_FILES[@]} * ${#FORMAT_LIST[@]} ))"
echo "Duration: ${SECONDS_DUR}s per clip"
[[ -n "$DUAL_OUTPUT" ]] && echo "Dual output: yes (2x videos per combination)"
echo ""

for CREATOR_FILE in "${CREATOR_FILES[@]}"; do
    CREATOR_NAME=$(basename "$CREATOR_FILE" .md | sed 's/creator-//')

    # Get character_id if available
    CHAR_ID=""
    if [[ -n "$CHARACTER_IDS_FILE" && -f "$CHARACTER_IDS_FILE" ]]; then
        CHAR_ID=$(jq -r --arg name "$CREATOR_NAME" '.[$name] // empty' "$CHARACTER_IDS_FILE")
    fi
    # Also check the creator file itself
    if [[ -z "$CHAR_ID" ]]; then
        CHAR_ID=$(grep -oP 'character_id:\s*\K\S+' "$CREATOR_FILE" 2>/dev/null || true)
    fi

    for FORMAT in "${FORMAT_LIST[@]}"; do
        TOTAL=$((TOTAL + 1))
        SLUG="${CREATOR_NAME}-${FORMAT}"
        PROMPT_FILE="$WORKSPACE/prompts/${SLUG}-prompt.txt"
        OUTPUT_FILE="$WORKSPACE/clips/${SLUG}.mp4"

        echo "--- [$TOTAL] $CREATOR_NAME × $FORMAT ---"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Would generate: $OUTPUT_FILE"
            [[ -n "$CHAR_ID" ]] && echo "  Character ID: $CHAR_ID"
            continue
        fi

        if [[ ! -f "$PROMPT_FILE" ]]; then
            echo "  ⚠ Missing prompt: $PROMPT_FILE (skipping)"
            echo "  Create this file with the scene description, then re-run."
            FAILED=$((FAILED + 1))
            continue
        fi

        EXTRA_ARGS=()
        [[ -n "$PRO" ]] && EXTRA_ARGS+=("$PRO")

        if bash "$SCRIPT_DIR/generate-clip.sh" \
            --prompt-file "$PROMPT_FILE" \
            --output "$OUTPUT_FILE" \
            --seconds "$SECONDS_DUR" \
            --log-file "$LOG_FILE" \
            --label "$SLUG" \
            "${EXTRA_ARGS[@]}"; then
            SUCCEEDED=$((SUCCEEDED + 1))
            echo "  ✓ $OUTPUT_FILE"
        else
            FAILED=$((FAILED + 1))
            echo "  ✗ Failed"
        fi

        echo ""
        # Brief pause between generations to avoid rate limits
        sleep 2
    done
done

echo ""
echo "=== Batch Complete ==="
echo "Total: $TOTAL | Succeeded: $SUCCEEDED | Failed: $FAILED"
echo "Log: $LOG_FILE"
echo "Clips: $WORKSPACE/clips/"
