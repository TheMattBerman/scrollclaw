#!/usr/bin/env bash
set -euo pipefail

# Scaffold a new creator profile from the template.
#
# Usage:
#   bash create-creator.sh <workspace-dir> <creator-name>
#   bash create-creator.sh campaigns/skincare maya

WORKSPACE="${1:-}"
NAME="${2:-}"

if [[ -z "$WORKSPACE" || -z "$NAME" ]]; then
    echo "Usage: create-creator.sh <workspace-dir> <creator-name>"
    echo "Example: create-creator.sh campaigns/skincare maya"
    exit 1
fi

CREATORS_DIR="$WORKSPACE/creators"
mkdir -p "$CREATORS_DIR"

OUTPUT="$CREATORS_DIR/creator-${NAME}.md"

if [[ -f "$OUTPUT" ]]; then
    echo "Creator profile already exists: $OUTPUT"
    echo "Edit it directly or delete and re-run."
    exit 0
fi

cat > "$OUTPUT" << 'TEMPLATE'
# Creator: NAME_PLACEHOLDER

## Visual Identity
- Age band:
- Gender presentation:
- Face shape:
- Skin tone:
- Hair:
- Facial hair:
- Build:
- Distinguishing features:
- Realism: normal-looking, not model-pretty

## Wardrobe
- Default:
- Alt 1:
- Alt 2:
- Never wears:

## Environment
- Primary:
- Alt 1:
- Alt 2:
- Background clutter:

## Voice
- Speaking energy:
- Verbal tics:
- Opinion style:
- Script register:

## Voice
- ElevenLabs voice_id:
- Model version: v3
- Source: voice design / instant clone
- Clone source:
- Room tone preset:

## Sora
- character_id:
- created_at:
- last_used:

## Prompt Invariants
Always include in every prompt for this creator:
- [age band], [gender presentation], [face shape], [skin tone]
- [hair description]
- [facial hair state]
- [build], [distinguishing features]
- [wardrobe for this scene]
- [environment clutter details]
- normal-looking, not model-pretty
- iPhone selfie-camera realism, handheld micro-shake
- practical lighting, not studio, not ring light
TEMPLATE

# Replace placeholder
sed -i "s/NAME_PLACEHOLDER/${NAME^}/" "$OUTPUT"

echo "Created: $OUTPUT"
echo "Fill in the profile, then use it with generate-first-frame.py --creator $OUTPUT"
