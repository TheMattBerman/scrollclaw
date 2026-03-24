---
name: scrollclaw-animate
description: "Animate first frames into A-roll talking head clips with Sora 2 via fal.ai. Motion prompting, dialogue sync, and content filter handling."
metadata:
  openclaw:
    emoji: "🎥"
    user-invocable: true
    triggers:
      - "animate clip"
      - "sora animate"
      - "generate clip"
      - "a-roll"
      - "talking head clip"
      - "sora video"
---

# Animate (A-Roll)

Sora 2 turns first frames into talking head clips with synced lip movement and audio. Image-to-video is the default — text-to-video is the fallback.

## Prerequisites

- First frame approved (from `/first-frame`)
- Script with `[A-ROLL]` segments tagged (from `/persona`)

## Motion Prompting

Read `references/motion-prompting.md` for the structured prompt format. Use labeled fields — not prose paragraphs:

- **Camera** — handheld energy, micro-shake, slight reframe
- **Subject** — keep generic (first frame defines appearance). Detailed facial descriptions trigger content safety filters
- **Dialogue** — include actual script lines. Sora generates synced lip movement + audio
- **Audio** — describe the RESULT not the gear. "Clean natural podcast audio, voice close and present, subtle room tone" works. Naming specific mics doesn't.
- **Environment & light** — practical light, deep focus, real-world setting
- **Style & mood** — iPhone selfie-camera realism, not cinematic

## Generation

**USE THE SCRIPTS. DO NOT construct API calls manually.** Scripts handle provider routing, field names, polling, downloading, and error handling.

```bash
# Image-to-video (RECOMMENDED — first frame locks the face)
bash scripts/generate-clip.sh \
  --provider fal \
  --image workspace/campaigns/<slug>/frames/frame1.png \
  --prompt-file workspace/campaigns/<slug>/motion-prompt.txt \
  --output workspace/campaigns/<slug>/clips/a-roll-01.mp4 \
  --log-file workspace/campaigns/<slug>/output-log.md \
  --label a-roll-01 \
  --seconds 8 --aspect-ratio portrait

# Text-to-video (fallback — no first frame)
bash scripts/generate-clip.sh \
  --provider fal \
  --prompt-file workspace/campaigns/<slug>/scene-prompt.txt \
  --output workspace/campaigns/<slug>/clips/a-roll-01.mp4 \
  --log-file workspace/campaigns/<slug>/output-log.md \
  --label a-roll-01 \
  --seconds 8 --aspect-ratio portrait

# Replicate fallback (if fal.ai is down)
bash scripts/generate-clip.sh \
  --provider replicate \
  --image workspace/campaigns/<slug>/frames/frame1.png \
  --prompt-file workspace/campaigns/<slug>/motion-prompt.txt \
  --output workspace/campaigns/<slug>/clips/a-roll-01.mp4 \
  --log-file workspace/campaigns/<slug>/output-log.md \
  --label a-roll-01 \
  --seconds 8 --aspect-ratio portrait
```

## API Reference

Read `references/sora-api.md` for endpoint details, queue workflow, field names, and duration options. fal.ai supports 4/8/12/16/20s. Replicate is limited to 4/8/12.

## Content Filter Handling

Sora's content filter runs AFTER generation — can fail at 99%. If blocked:
- Soften the motion prompt (keep first frame)
- Remove any potentially sensitive descriptions
- Retry with adjusted prompt

## Key Findings

- Include actual script in Dialogue field — Sora generates synced lip movement
- For podcast audio: describe the RESULT, not the gear
- Keep Subject descriptions generic — the first frame already defines appearance
- fal.ai is primary provider; Replicate is backup

## Brand Memory Integration

### Reads
| File | Purpose |
|------|---------|
| `workspace/campaigns/<slug>/frames/frame1.png` | Canonical face — fed to Sora i2v to lock creator identity |
| `workspace/campaigns/<slug>/scripts/<format>-script.md` | A-roll segments, dialogue, shot timing |
| `workspace/campaigns/<slug>/creators/creator-<name>.md` | Creator energy/vibe reference for motion prompting |
| `workspace/creators/creator-<name>.md` | Fallback if no campaign-specific profile exists |

### Writes
| File | Notes |
|------|-------|
| `workspace/campaigns/<slug>/clips/a-roll-01.mp4` | One file per A-roll segment |
| `workspace/campaigns/<slug>/output-log.md` | Motion prompt, model, duration, provider (append-only) |

### Context loading

```
🎥 Animate context loaded:
  ✓ First frame: workspace/campaigns/ridge-q1/frames/frame1.png
  ✓ Script: talking-head (A-roll segments: 3)
  ✓ Creator: Maya
  ✓ Campaign: ridge-q1
```

## Contract

### Input
- Required: approved `frame1.png` plus a script with `[A-ROLL]` segments
- Optional: creator profile details, alternate prompt file, fallback provider
- Format: workspace image and markdown files plus motion prompt text
- Source: `/first-frame`, `/persona`, and `references/motion-prompting.md`

### Output
- Produces: one A-roll clip per `[A-ROLL]` segment plus append-only generation logs
- Format: MP4 files in `workspace/campaigns/<slug>/clips/` and rows in `output-log.md`
- Default behavior: use Sora image-to-video with the approved first frame; use text-to-video only as a fallback when no usable frame exists
- Downstream use: `/b-roll` and `/assemble`

### Validation
- Pre-conditions: first frame is approved, script is tagged correctly, and the prompt includes the actual dialogue
- Post-conditions: local MP4 is saved, creator identity holds, and lip movement/audio feel believable enough to cut into a final video
- Failure checks: reroll or adjust the prompt if content filters fail, the hands/face break realism, or the clip is too synthetic to pass downstream

## Output

- A-roll clips (MP4) in `workspace/campaigns/<slug>/clips/`
- Each clip named `a-roll-<segment>.mp4` corresponding to an `[A-ROLL]` script segment
- Generation params logged to `workspace/campaigns/<slug>/output-log.md`

## Next Step

A-roll done → run `/b-roll` for environment shots, or `/assemble` if no B-roll needed.
