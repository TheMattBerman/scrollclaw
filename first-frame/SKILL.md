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
- Creator profile exists in `creators/`
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
  --prompt-file campaigns/<slug>/frame1-prompt.txt \
  --output-file campaigns/<slug>/frames/frame1.png \
  --creator creators/creator-<name>.md \
  --log-file campaigns/<slug>/output-log.md \
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

## Output

- Canonical first frame image (PNG) in `campaigns/<slug>/frames/`
- Context-specific frames for multi-setting formats
- Prompt file and output log saved

## Next Step

Frame 1 approved → run `/animate` for A-roll or `/b-roll` for environment shots.
