#!/usr/bin/env bash
set -euo pipefail

# Generate a video clip via Sora 2 on fal.ai (default) or Replicate.
# Supports both text-to-video and image-to-video (first frame).
#
# Usage:
#   # Text to video (fal.ai, default)
#   bash generate-clip.sh --prompt-file scene.txt --output clip.mp4 --seconds 8
#
#   # Image to video (fal.ai)
#   bash generate-clip.sh --image frame1.png --prompt-file motion.txt --output clip.mp4 --seconds 8
#
#   # Via Replicate
#   bash generate-clip.sh --provider replicate --prompt-file scene.txt --output clip.mp4 --seconds 8
#
#   # With character consistency (Replicate only)
#   bash generate-clip.sh --provider replicate --prompt-file scene.txt --output clip.mp4 --character-id char_123
#
#   # Dual output (16:9 + 9:16)
#   bash generate-clip.sh --prompt-file scene.txt --output clip.mp4 --dual-output

PROMPT_FILE=""
IMAGE=""
OUTPUT=""
SECONDS_DUR="8"
ASPECT_RATIO="portrait"
PRO="false"
PROVIDER="fal"
POLL_INTERVAL=10
TIMEOUT=600
LOG_FILE=""
LABEL="clip"

usage() {
    echo "Usage: generate-clip.sh --prompt-file FILE --output FILE [options]"
    echo ""
    echo "Options:"
    echo "  --prompt-file FILE    Scene/motion description (required)"
    echo "  --image FILE          First frame image for i2v mode (optional)"
    echo "  --output FILE         Output video path (required)"
    echo "  --seconds N           Duration in seconds (default: 8)"
    echo "  --aspect-ratio RATIO  portrait or landscape (default: portrait)"
    echo "  --pro                 Use Sora 2 Pro model"
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
        --pro) PRO="true"; shift ;;
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

# ---------------------------------------------------------------------------
# fal.ai provider
# ---------------------------------------------------------------------------
generate_fal() {
    [[ -z "${FAL_KEY:-}" ]] && { echo "Error: FAL_KEY not set"; exit 2; }

    # Map aspect_ratio names: portrait -> 9:16, landscape -> 16:9, pass through ratios
    FAL_ASPECT="$ASPECT_RATIO"
    [[ "$ASPECT_RATIO" == "portrait" ]] && FAL_ASPECT="9:16"
    [[ "$ASPECT_RATIO" == "landscape" ]] && FAL_ASPECT="16:9"

    # fal.ai Sora duration must be one of: 4, 8, 12, 16, 20
    FAL_DURATION="$SECONDS_DUR"

    # Choose endpoint
    if [[ -n "$IMAGE" ]]; then
        if [[ "$PRO" == "true" ]]; then
            ENDPOINT="https://queue.fal.run/fal-ai/sora-2/image-to-video/pro"
        else
            ENDPOINT="https://queue.fal.run/fal-ai/sora-2/image-to-video"
        fi
        INPUT_JSON=$(jq -n \
            --arg prompt "$PROMPT" \
            --arg image "$IMAGE" \
            --argjson duration "$FAL_DURATION" \
            --arg ar "$FAL_ASPECT" \
            '{prompt: $prompt, image_url: $image, duration: $duration, aspect_ratio: $ar}')
        echo "Mode: image-to-video (Sora i2v via fal.ai)"
    else
        if [[ "$PRO" == "true" ]]; then
            ENDPOINT="https://queue.fal.run/fal-ai/sora-2/text-to-video/pro"
        else
            ENDPOINT="https://queue.fal.run/fal-ai/sora-2/text-to-video"
        fi
        INPUT_JSON=$(jq -n \
            --arg prompt "$PROMPT" \
            --argjson duration "$FAL_DURATION" \
            --arg ar "$FAL_ASPECT" \
            '{prompt: $prompt, duration: $duration, aspect_ratio: $ar}')
        echo "Mode: text-to-video (Sora t2v via fal.ai)"
    fi

    echo "Endpoint: $ENDPOINT"
    echo "Duration: ${FAL_DURATION}s | Aspect: $FAL_ASPECT"

    # Submit to queue
    RESPONSE=$(curl -s -X POST "$ENDPOINT" \
        -H "Authorization: Key $FAL_KEY" \
        -H "Content-Type: application/json" \
        -d "$INPUT_JSON")

    # Use the exact status_url returned by fal.ai
    STATUS_URL=$(echo "$RESPONSE" | jq -r '.status_url // empty')
    REQUEST_ID=$(echo "$RESPONSE" | jq -r '.request_id // empty')

    if [[ -z "$STATUS_URL" || -z "$REQUEST_ID" ]]; then
        echo "Error submitting to fal.ai:" >&2
        echo "$RESPONSE" | jq . >&2
        exit 1
    fi

    echo "Request: $REQUEST_ID"
    echo "Polling: $STATUS_URL"

    START_TIME=$(date +%s)
    while true; do
        POLL=$(curl -s -H "Authorization: Key $FAL_KEY" "$STATUS_URL")
        STATUS=$(echo "$POLL" | jq -r '.status')

        case "$STATUS" in
            COMPLETED)
                echo "Generation complete!"
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
    VIDEO_URL=$(echo "$RESULT" | jq -r '.video.url // empty')
    if [[ -z "$VIDEO_URL" || "$VIDEO_URL" == "null" ]]; then
        echo "Error: No video URL in response" >&2
        echo "$RESULT" | jq . >&2
        exit 1
    fi

    curl -s -o "$OUTPUT" "$VIDEO_URL"
    echo "Saved: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"

    # Log if requested
    if [[ -n "$LOG_FILE" ]]; then
        TIMESTAMP=$(date -Iseconds)
        mkdir -p "$(dirname "$LOG_FILE")"
        if [[ ! -f "$LOG_FILE" ]]; then
            echo '# Output Log' > "$LOG_FILE"
            echo '' >> "$LOG_FILE"
            echo '| Timestamp | Label | Model | Seconds | Output | Notes |' >> "$LOG_FILE"
            echo '|---|---|---|---|---|---|' >> "$LOG_FILE"
        fi
        echo "| $TIMESTAMP | $LABEL | fal-ai/sora-2-pro | $FAL_DURATION | $OUTPUT | request=$REQUEST_ID |" >> "$LOG_FILE"
    fi

    echo ""
    echo "Done. Request ID: $REQUEST_ID"
}

# ---------------------------------------------------------------------------
# Replicate provider
# ---------------------------------------------------------------------------
generate_replicate() {
    [[ -z "${REPLICATE_API_TOKEN:-}" ]] && { echo "Error: REPLICATE_API_TOKEN not set"; exit 2; }

    # Determine model path
    if [[ "$PRO" == "true" ]]; then
        MODEL_PATH="openai/sora-2-pro"
    else
        MODEL_PATH="openai/sora-2"
    fi

    # Build input JSON
    INPUT_JSON=$(cat <<EOF
{
    "prompt": $(echo "$PROMPT" | jq -Rs .),
    "seconds": $SECONDS_DUR,
    "aspect_ratio": "$ASPECT_RATIO"
}
EOF
    )

    # Add first frame for i2v
    if [[ -n "$IMAGE" ]]; then
        if [[ "$IMAGE" == http* ]]; then
            INPUT_JSON=$(echo "$INPUT_JSON" | jq --arg img "$IMAGE" '. + {input_reference: $img}')
        else
            # Upload local file to Replicate first
            echo "Uploading first frame to Replicate..."
            UPLOAD_RESP=$(curl -s -X POST "https://api.replicate.com/v1/files" \
                -H "Authorization: Token $REPLICATE_API_TOKEN" \
                -F "content=@$IMAGE" \
                -F "content_type=image/png")
            FILE_URL=$(echo "$UPLOAD_RESP" | jq -r '.urls.get // empty')
            if [[ -z "$FILE_URL" ]]; then
                echo "Error uploading file:" >&2
                echo "$UPLOAD_RESP" | jq . >&2
                exit 1
            fi
            echo "Uploaded: $FILE_URL"
            INPUT_JSON=$(echo "$INPUT_JSON" | jq --arg img "$FILE_URL" '. + {input_reference: $img}')
        fi
    fi

    PAYLOAD=$(jq -n --argjson input "$INPUT_JSON" '{input: $input}')

    echo "Creating prediction with $MODEL_PATH..."
    echo "Duration: ${SECONDS_DUR}s | Aspect: $ASPECT_RATIO"
    [[ -n "$IMAGE" ]] && echo "Mode: image-to-video (first frame)"

    RESPONSE=$(curl -s -X POST "https://api.replicate.com/v1/models/${MODEL_PATH}/predictions" \
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

    # Output is a single MP4 URL string (not an array)
    VIDEO_URL=$(echo "$POLL" | jq -r '.output // empty')
    if [[ -n "$VIDEO_URL" && "$VIDEO_URL" != "null" ]]; then
        curl -s -o "$OUTPUT" "$VIDEO_URL"
        echo "Saved: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
    else
        echo "Error: No output URL in response" >&2
        echo "$POLL" | jq '.output' >&2
        exit 1
    fi

    # Log if requested
    if [[ -n "$LOG_FILE" ]]; then
        TIMESTAMP=$(date -Iseconds)
        mkdir -p "$(dirname "$LOG_FILE")"
        if [[ ! -f "$LOG_FILE" ]]; then
            echo '# Output Log' > "$LOG_FILE"
            echo '' >> "$LOG_FILE"
            echo '| Timestamp | Label | Model | Seconds | Output | Notes |' >> "$LOG_FILE"
            echo '|---|---|---|---|---|---|' >> "$LOG_FILE"
        fi
        echo "| $TIMESTAMP | $LABEL | $MODEL_PATH | $SECONDS_DUR | $OUTPUT | prediction=$PREDICTION_ID |" >> "$LOG_FILE"
    fi

    echo ""
    echo "Done. Prediction ID: $PREDICTION_ID"
}

# ---------------------------------------------------------------------------
# Dispatch by provider
# ---------------------------------------------------------------------------
case "$PROVIDER" in
    fal)
        generate_fal
        ;;
    replicate)
        generate_replicate
        ;;
    *)
        echo "Error: unknown provider '$PROVIDER' (use 'fal' or 'replicate')" >&2
        exit 1
        ;;
esac
