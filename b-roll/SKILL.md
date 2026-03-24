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
  --image workspace/campaigns/<slug>/frames/environment-frame.png \
  --prompt-file workspace/campaigns/<slug>/broll-prompt.txt \
  --output workspace/campaigns/<slug>/clips/b-roll-01.mp4 \
  --log-file workspace/campaigns/<slug>/output-log.md \
  --label b-roll-01 \
  --seconds 5

# Faceless B-roll (no start frame needed)
bash scripts/generate-broll.sh \
  --provider fal \
  --prompt-file workspace/campaigns/<slug>/broll-prompt.txt \
  --output workspace/campaigns/<slug>/clips/b-roll-02.mp4 \
  --log-file workspace/campaigns/<slug>/output-log.md \
  --label b-roll-02 \
  --seconds 5
```

## API Reference

Read `references/kling-api.md` for Kling 3 endpoint details, field names, and queue workflow on fal.ai.

## Key Findings

- Kling generates in ~100s vs Sora's 5-10 min. Use Kling for ALL B-roll.
- Same character face image feeds both engines for identity consistency
- **AI cannot generate realistic app screens or UI text.** For product/app demos: use real screenshots or screen recordings.
- The orchestrator doc (`references/orchestrator.md`) has the full A/B-roll split methodology

## Brand Memory Integration

### Reads
| File | Purpose |
|------|---------|
| `workspace/campaigns/<slug>/frames/environment-frame.png` | Environment-matched start frame for Kling i2v |
| `workspace/campaigns/<slug>/clips/a-roll-*.mp4` | Source clips to extract environment frames from |
| `workspace/campaigns/<slug>/scripts/<format>-script.md` | B-roll segments and visual cues |

### Writes
| File | Notes |
|------|-------|
| `workspace/campaigns/<slug>/clips/b-roll-01.mp4` | One file per B-roll segment |
| `workspace/campaigns/<slug>/output-log.md` | Kling prompt, duration, provider (append-only) |

### Context loading

```
🎞️ B-Roll context loaded:
  ✓ Environment frame: workspace/campaigns/ridge-q1/frames/environment-frame.png
  ✓ A-roll clips: 3 found (workspace/campaigns/ridge-q1/clips/)
  ✓ Script: talking-head (B-roll segments: 2)
  ✓ Campaign: ridge-q1
```

## Contract

### Input
- Required: `[B-ROLL]` script segments plus either an environment frame or usable A-roll clips for extraction
- Optional: product screenshots, faceless B-roll prompts, campaign brief for scene grounding
- Format: workspace image/video files plus B-roll prompt text
- Source: `/animate`, `/persona`, and `references/orchestrator.md`

### Output
- Produces: one visual-only B-roll clip per segment plus append-only generation logs
- Format: MP4 files in `workspace/campaigns/<slug>/clips/` and rows in `output-log.md`
- Default behavior: use Kling with an environment-matched start frame; for app demos, use real screenshots or recordings instead of AI UI generation
- Downstream use: `/assemble`

### Validation
- Pre-conditions: the cut point is clear in the script and there is enough scene context to match the A-roll environment
- Post-conditions: clip visually fits the voice beat, feels like the same world as the A-roll, and saves locally
- Failure checks: do not accept stock-looking B-roll, mismatched rooms, or fake app UI when the product needs a real screen

## Output

- B-roll clips (MP4) in `workspace/campaigns/<slug>/clips/`
- Each clip named `b-roll-<segment>.mp4` corresponding to a `[B-ROLL]` script segment
- Clips are visual-only — no dialogue
- Generation params logged to `workspace/campaigns/<slug>/output-log.md`

## Next Step

B-roll done → run `/assemble` to stitch everything together with unified audio.
