#!/usr/bin/env bash
set -euo pipefail

# Generate B-roll video via Kling 3 on fal.ai (primary) or Replicate (fallback).
# Supports both text-to-video and image-to-video (start image).
#
# Usage:
#   # Text to video (fal.ai)
#   bash generate-broll.sh --prompt-file scene.txt --output broll.mp4 --seconds 5
#
#   # Image to video (fal.ai)
#   bash generate-broll.sh --image product.png --prompt-file motion.txt --output broll.mp4
#
#   # Force Replicate fallback
#   bash generate-broll.sh --provider replicate --prompt-file scene.txt --output broll.mp4

PROMPT_FILE=""
IMAGE=""
OUTPUT=""
SECONDS_DUR="5"
ASPECT_RATIO="9:16"
GENERATE_AUDIO="true"
PROVIDER="fal"
POLL_INTERVAL=10
TIMEOUT=600
LOG_FILE=""
LABEL="broll"

usage() {
    echo "Usage: generate-broll.sh --prompt-file FILE --output FILE [options]"
    echo ""
    echo "Options:"
    echo "  --prompt-file FILE    Scene/motion description (required)"
    echo "  --image FILE          Start image URL for i2v mode (optional)"
    echo "  --output FILE         Output video path (required)"
    echo "  --seconds N           Duration in seconds, 3-15 (default: 5)"
    echo "  --aspect-ratio RATIO  Aspect ratio (default: 9:16)"
    echo "  --no-audio            Disable audio generation"
    echo "  --provider NAME       fal or replicate (default: fal)"
    echo "  --log-file FILE       Append to output log"
    echo "  --label TEXT          Label for log entry"
    echo "  --timeout N           Timeout in seconds (default: 600)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt-file) PROMPT_FILE="$2"; shift 2 ;;
        --image) IMAGE="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --seconds) SECONDS_DUR="$2"; shift 2 ;;
        --aspect-ratio) ASPECT_RATIO="$2"; shift 2 ;;
        --no-audio) GENERATE_AUDIO="false"; shift ;;
        --provider) PROVIDER="$2"; shift 2 ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        --label) LABEL="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$PROMPT_FILE" ]] && { echo "Error: --prompt-file is required"; usage; }
[[ -z "$OUTPUT" ]] && { echo "Error: --output is required"; usage; }

PROMPT=$(cat "$PROMPT_FILE")

# Validate duration
if [[ "$SECONDS_DUR" -lt 3 || "$SECONDS_DUR" -gt 15 ]]; then
    echo "Error: --seconds must be between 3 and 15" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# fal.ai provider
# ---------------------------------------------------------------------------
generate_fal() {
    [[ -z "${FAL_KEY:-}" ]] && { echo "Error: FAL_KEY not set"; exit 2; }

    # Choose endpoint: i2v if image provided, t2v otherwise
    if [[ -n "$IMAGE" ]]; then
        ENDPOINT="https://queue.fal.run/fal-ai/kling-video/v3/pro/image-to-video"
        INPUT_JSON=$(jq -n \
            --arg prompt "$PROMPT" \
            --arg image "$IMAGE" \
            --argjson duration "$SECONDS_DUR" \
            --arg ar "$ASPECT_RATIO" \
            --argjson audio "$GENERATE_AUDIO" \
            '{prompt: $prompt, start_image_url: $image, duration: $duration, aspect_ratio: $ar, generate_audio: $audio}')
        echo "Mode: image-to-video (Kling i2v via fal.ai)"
    else
        ENDPOINT="https://queue.fal.run/fal-ai/kling-video/v3/pro/text-to-video"
        INPUT_JSON=$(jq -n \
            --arg prompt "$PROMPT" \
            --argjson duration "$SECONDS_DUR" \
            --arg ar "$ASPECT_RATIO" \
            --argjson audio "$GENERATE_AUDIO" \
            '{prompt: $prompt, duration: $duration, aspect_ratio: $ar, generate_audio: $audio}')
        echo "Mode: text-to-video (Kling t2v via fal.ai)"
    fi

    echo "Endpoint: $ENDPOINT"
    echo "Duration: ${SECONDS_DUR}s | Aspect: $ASPECT_RATIO | Audio: $GENERATE_AUDIO"

    # Submit to queue
    RESPONSE=$(curl -s -X POST "$ENDPOINT" \
        -H "Authorization: Key $FAL_KEY" \
        -H "Content-Type: application/json" \
        -d "$INPUT_JSON")

    # Use the exact status_url returned by fal.ai — do NOT construct manually
    STATUS_URL=$(echo "$RESPONSE" | jq -r '.status_url // empty')
    REQUEST_ID=$(echo "$RESPONSE" | jq -r '.request_id // empty')

    if [[ -z "$STATUS_URL" || -z "$REQUEST_ID" ]]; then
        echo "Error submitting to fal.ai:" >&2
        echo "$RESPONSE" | jq . >&2
        exit 1
    fi

    echo "Request: $REQUEST_ID"
    echo "Polling: $STATUS_URL"

    # Poll using the exact status_url
    START_TIME=$(date +%s)
    while true; do
        POLL=$(curl -s -H "Authorization: Key $FAL_KEY" "$STATUS_URL")
        STATUS=$(echo "$POLL" | jq -r '.status')

        case "$STATUS" in
            COMPLETED)
                echo "Generation complete!"
                # Fetch the result from the response_url
                RESPONSE_URL=$(echo "$RESPONSE" | jq -r '.response_url // empty')
                if [[ -n "$RESPONSE_URL" ]]; then
                    RESULT=$(curl -s -H "Authorization: Key $FAL_KEY" "$RESPONSE_URL")
                else
                    RESULT="$POLL"
                fi
                break
                ;;
            FAILED)
                ERROR=$(echo "$POLL" | jq -r '.error // "unknown error"')
                echo "Generation failed: $ERROR" >&2
                return 1
                ;;
            *)
                ELAPSED=$(( $(date +%s) - START_TIME ))
                if [[ $ELAPSED -gt $TIMEOUT ]]; then
                    echo "Timeout after ${TIMEOUT}s" >&2
                    return 1
                fi
                echo "  Status: $STATUS (${ELAPSED}s elapsed)"
                sleep "$POLL_INTERVAL"
                ;;
        esac
    done

    # Download output — fal.ai returns video url in .video.url
    VIDEO_URL=$(echo "$RESULT" | jq -r '.video.url // empty')
    if [[ -z "$VIDEO_URL" || "$VIDEO_URL" == "null" ]]; then
        echo "Error: No video URL in response" >&2
        echo "$RESULT" | jq . >&2
        return 1
    fi

    mkdir -p "$(dirname "$OUTPUT")"
    curl -s -o "$OUTPUT" "$VIDEO_URL"
    echo "Saved: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"

    # Log
    if [[ -n "$LOG_FILE" ]]; then
        log_entry "fal-ai/kling-v3-pro" "$REQUEST_ID"
    fi

    echo ""
    echo "Done. Request ID: $REQUEST_ID"
}

# ---------------------------------------------------------------------------
# Replicate provider (fallback)
# ---------------------------------------------------------------------------
generate_replicate() {
    [[ -z "${REPLICATE_API_TOKEN:-}" ]] && { echo "Error: REPLICATE_API_TOKEN not set"; exit 2; }

    MODEL="kwaivgi/kling-v3-omni-video"

    # Build input JSON
    INPUT_JSON=$(jq -n \
        --arg prompt "$PROMPT" \
        --argjson duration "$SECONDS_DUR" \
        --arg ar "$ASPECT_RATIO" \
        '{prompt: $prompt, duration: $duration, aspect_ratio: $ar}')

    if [[ -n "$IMAGE" ]]; then
        INPUT_JSON=$(echo "$INPUT_JSON" | jq --arg img "$IMAGE" '. + {start_image: $img}')
        echo "Mode: image-to-video (Kling Omni via Replicate)"
    else
        echo "Mode: text-to-video (Kling Omni via Replicate)"
    fi

    PAYLOAD=$(jq -n --argjson input "$INPUT_JSON" '{input: $input}')

    echo "Model: $MODEL"
    echo "Duration: ${SECONDS_DUR}s | Aspect: $ASPECT_RATIO"

    RESPONSE=$(curl -s -X POST "https://api.replicate.com/v1/models/${MODEL}/predictions" \
        -H "Authorization: Token $REPLICATE_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")

    PREDICTION_ID=$(echo "$RESPONSE" | jq -r '.id // empty')
    GET_URL=$(echo "$RESPONSE" | jq -r '.urls.get // empty')

    if [[ -z "$PREDICTION_ID" || -z "$GET_URL" ]]; then
        echo "Error creating prediction:" >&2
        echo "$RESPONSE" | jq . >&2
        exit 1
    fi

    echo "Prediction: $PREDICTION_ID"
    echo "Polling..."

    START_TIME=$(date +%s)
    while true; do
        POLL=$(curl -s -H "Authorization: Token $REPLICATE_API_TOKEN" "$GET_URL")
        STATUS=$(echo "$POLL" | jq -r '.status')

        case "$STATUS" in
            succeeded)
                echo "Generation complete!"
                break
                ;;
            failed|canceled)
                ERROR=$(echo "$POLL" | jq -r '.error // "unknown error"')
                echo "Generation $STATUS: $ERROR" >&2
                exit 1
                ;;
            *)
                ELAPSED=$(( $(date +%s) - START_TIME ))
                if [[ $ELAPSED -gt $TIMEOUT ]]; then
                    echo "Timeout after ${TIMEOUT}s" >&2
                    exit 1
                fi
                echo "  Status: $STATUS (${ELAPSED}s elapsed)"
                sleep "$POLL_INTERVAL"
                ;;
        esac
    done

    # Download output
    mkdir -p "$(dirname "$OUTPUT")"
    VIDEO_URL=$(echo "$POLL" | jq -r '.output // empty')
    if [[ -n "$VIDEO_URL" && "$VIDEO_URL" != "null" ]]; then
        curl -s -o "$OUTPUT" "$VIDEO_URL"
        echo "Saved: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
    else
        echo "Error: No output URL in response" >&2
        echo "$POLL" | jq '.output' >&2
        exit 1
    fi

    # Log
    if [[ -n "$LOG_FILE" ]]; then
        log_entry "$MODEL" "$PREDICTION_ID"
    fi

    echo ""
    echo "Done. Prediction ID: $PREDICTION_ID"
}

# ---------------------------------------------------------------------------
# Shared logging
# ---------------------------------------------------------------------------
log_entry() {
    local model="$1"
    local run_id="$2"
    TIMESTAMP=$(date -Iseconds)
    mkdir -p "$(dirname "$LOG_FILE")"
    if [[ ! -f "$LOG_FILE" ]]; then
        echo '# Output Log' > "$LOG_FILE"
        echo '' >> "$LOG_FILE"
        echo '| Timestamp | Label | Model | Seconds | Provider | Output | Notes |' >> "$LOG_FILE"
        echo '|---|---|---|---|---|---|---|' >> "$LOG_FILE"
    fi
    echo "| $TIMESTAMP | $LABEL | $model | $SECONDS_DUR | $PROVIDER | $OUTPUT | id=$run_id |" >> "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$PROVIDER" in
    fal)
        if ! generate_fal; then
            echo ""
            echo "fal.ai failed — falling back to Replicate..."
            PROVIDER="replicate"
            generate_replicate
        fi
        ;;
    replicate)
        generate_replicate
        ;;
    *)
        echo "Error: unknown provider '$PROVIDER' (use 'fal' or 'replicate')" >&2
        exit 1
        ;;
esac
