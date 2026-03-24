---
name: scrollclaw-broll
description: "Generate B-roll environment and product shots with Kling 3 via fal.ai. Environment matching, cut timing, and visual-only clips that play under continuous voice."
metadata:
  openclaw:
    emoji: "🎞️"
    user-invocable: true
    triggers:
      - "b-roll"
      - "kling video"
      - "environment shot"
      - "product shot"
      - "broll"
      - "b roll"
---

# B-Roll (Kling 3)

Kling 3 generates B-roll — environment shots, product close-ups, lifestyle moments. These are visual-only clips that play under the continuous voice track. Voice never cuts. B-roll swaps visuals only.

## Prerequisites

- Script with `[B-ROLL]` segments tagged (from `/persona`)
- A-roll clips generated (from `/animate`) — needed for environment matching

## Environment Matching

Extract a frame from the A-roll and use it as Kling's start image. This ensures B-roll looks like the same room — same floor, same lighting, same vibe. See `references/orchestrator.md`.

Generate **context-specific first frames** per scene. Don't use the podcast frame (headphones) for gym B-roll.

## Cut Timing

Cut from A-roll to B-roll at a script BEAT point — not mid-sentence. The viewer should see the face deliver the setup, then cut to B-roll for the payoff visual.

Example: If Sarah says "she finishes the whole bowl" → cut to dog finishing the bowl. Match the visual to the words. Leave 0.5-1s buffer before the cut so the face isn't visible in a non-talking state.

## Generation

**USE `scripts/generate-broll.sh` — do NOT construct Kling API calls manually.**

```bash
# B-roll with environment-matched start frame (RECOMMENDED)
bash scripts/generate-broll.sh \
  --provider fal \
  --image campaigns/<slug>/frames/environment-frame.png \
  --prompt-file campaigns/<slug>/broll-prompt.txt \
  --output campaigns/<slug>/clips/broll-01.mp4 \
  --seconds 5

# Faceless B-roll (no start frame needed)
bash scripts/generate-broll.sh \
  --provider fal \
  --prompt-file campaigns/<slug>/broll-prompt.txt \
  --output campaigns/<slug>/clips/broll-02.mp4 \
  --seconds 5
```

## API Reference

Read `references/kling-api.md` for Kling 3 endpoint details, field names, and queue workflow on fal.ai.

## Key Findings

- Kling generates in ~100s vs Sora's 5-10 min. Use Kling for ALL B-roll.
- Same character face image feeds both engines for identity consistency
- **AI cannot generate realistic app screens or UI text.** For product/app demos: use real screenshots or screen recordings.
- The orchestrator doc (`references/orchestrator.md`) has the full A/B-roll split methodology

## Output

- B-roll clips (MP4) in `campaigns/<slug>/clips/`
- Each clip corresponds to a `[B-ROLL]` script segment
- Clips are visual-only — no dialogue

## Next Step

B-roll done → run `/assemble` to stitch everything together with unified audio.
