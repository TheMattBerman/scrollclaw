---
name: scrollclaw-first-frame
description: "Generate the canonical first frame with Nano Banana 2. Composition, character, environment, and color — all locked before animation. The visual design gate."
metadata:
  openclaw:
    emoji: "🖼️"
    user-invocable: true
    triggers:
      - "first frame"
      - "generate frame"
      - "nano banana"
      - "ugc frame"
      - "canonical face"
---

# First Frame

The viewer's brain makes a stay-or-scroll decision in 3-5 seconds at the visual processing level — before conscious attention. By the time they've read the hook, the decision is already made.

Frame 1 is a visual design problem, not a copywriting problem. Read `references/first-frame-psychology.md` for emoji pattern interrupts, composition rules, and testing approach.

## Prerequisites

- Script approved (from `/persona`)
- Creator profile exists in `workspace/campaigns/<slug>/creators/` or `workspace/creators/`
- Brand context loaded

## Prompt Structure (Three Layers)

Read `references/first-frame-prompting.md` for the full system. This is what makes images look like phone photos instead of AI.

1. **Photorealism pre-prompt** — "Raw iPhone 14 photo. Candid moment, unfiltered..." + realism rules + negative prompt (CGI, 3D render, perfect skin, cinematic color grading)
2. **Color reference JSON** — extracted from a real reference photo, not described in text. See `_system/references/color-reference-system.md`.
3. **Scene description** — creator identity + environment + expression + composition

Include "no text, no words, no letters, no writing" in negative prompt to prevent Sora from hallucinating text into the video.

## Generation

```bash
python3 scripts/generate-first-frame.py \
  --prompt-file workspace/campaigns/<slug>/frame1-prompt.txt \
  --output-file workspace/campaigns/<slug>/frames/frame1.png \
  --creator workspace/campaigns/<slug>/creators/creator-<name>.md \
  --log-file workspace/campaigns/<slug>/output-log.md \
  --aspect-ratio "9:16"
```

## Multi-Frame Formats (Visual Reference Chaining)

For formats with multiple settings (podcast Dan, gym Dan, car Dan):

1. Generate frame 1 FIRST (the canonical face)
2. Review and approve frame 1
3. ALL subsequent frames MUST use frame 1 as visual reference
4. Do NOT generate frames in parallel from text descriptions alone — causes face drift
5. For Visual Transformation (5-6 frames): generate sequentially, each referencing frame 1

Generate **context-specific first frames** — one per setting. But always chain from the canonical face. Don't feed a podcast frame into gym B-roll.

## Iteration

Iterate on frame 1 more than anything else. Expect 2-4 attempts before it passes.

**Quality checks:**
- Does it look like a phone photo or an AI render?
- Is the creator believable (not model-pretty)?
- Is there real-world clutter in the environment?
- Does the color match the reference JSON?
- Is skin texture visible (pores, not porcelain)?

Once frame 1 is locked, the rest chain from it.

## Brand Memory Integration

### Reads
| File | Purpose |
|------|---------|
| `workspace/campaigns/<slug>/creators/creator-<name>.md` | Creator identity — face, hair, build, wardrobe, energy |
| `workspace/creators/creator-<name>.md` | Global creator profile (fallback if no campaign override exists) |
| `workspace/campaigns/<slug>/scripts/<format>-script.md` | Which scene/setting the first frame needs to establish |
| `workspace/campaigns/<slug>/brief.md` | Brand context, color cues, environment direction |

### Writes
| File | Notes |
|------|-------|
| `workspace/campaigns/<slug>/frames/frame1.png` | Canonical face — referenced by all subsequent frames and animation |
| `workspace/campaigns/<slug>/frames/environment-frame.png` | Context-specific frames for multi-setting formats |
| `workspace/campaigns/<slug>/output-log.md` | Prompt params, model version, generation time (append-only) |

### Context loading

```
🖼️ First Frame context loaded:
  ✓ Creator: Maya (workspace/campaigns/ridge-q1/creators/creator-maya.md)
  ✓ Script: talking-head (workspace/campaigns/ridge-q1/scripts/talking-head-script.md)
  ✓ Campaign: ridge-q1
```

## Contract

### Input
- Required: approved script plus a creator profile
- Optional: campaign brief, color reference inputs, global creator fallback profile
- Format: workspace markdown files plus prompt text
- Source: `/persona`, `workspace/campaigns/<slug>/brief.md`, and `_system/references/color-reference-system.md`

### Output
- Produces: one canonical face image and any context-specific environment frames needed for the format
- Format: PNG files in `workspace/campaigns/<slug>/frames/` plus prompt log entries in `output-log.md`
- Default behavior: generate `frame1.png` first, stop for review, then chain any additional frames from it
- Downstream use: `/animate` and `/b-roll`

### Validation
- Pre-conditions: script is approved, creator profile exists, and the target setting is clear enough to visualize
- Post-conditions: frame looks like a phone photo, preserves creator identity, and is strong enough to chain into later generations
- Failure checks: reroll or revise if the image looks like an AI render, the identity drifts, or the scene lacks believable real-world clutter

## Output

- Canonical first frame image (PNG) in `workspace/campaigns/<slug>/frames/`
- Context-specific frames for multi-setting formats in `workspace/campaigns/<slug>/frames/`
- Prompt params logged to `workspace/campaigns/<slug>/output-log.md`

## Next Step

Frame 1 approved → run `/animate` for A-roll or `/b-roll` for environment shots.
