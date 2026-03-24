---
name: scrollclaw-assemble
description: "Stitch clips, unify voice with ElevenLabs S2S, apply post-production realism stack, and burn captions. The final assembly pipeline."
metadata:
  openclaw:
    emoji: "🔧"
    user-invocable: true
    triggers:
      - "assemble video"
      - "stitch clips"
      - "post production"
      - "add captions"
      - "ugc captions"
      - "ugc audio"
      - "ugc post-production"
---

# Assemble

Three stages: stitch + audio → post-production → captions. Order matters.

## Prerequisites

- A-roll clips from `/animate`
- B-roll clips from `/b-roll` (if applicable)
- Script with timing from `/persona`

## Stage 1: Stitch + Audio Orchestration

Read `references/audio-orchestration.md` for the full process.

**The critical ordering (tested):**
1. Stitch A-roll clips ONLY (these drive the timeline)
2. Extract audio → run through ElevenLabs S2S → one consistent voice
3. Lay S2S voice back on A-roll video
4. Cut A-roll at B-roll insertion points
5. Insert B-roll clips as VISUAL-ONLY (no audio) at timestamps matching the script
6. Lay S2S voice on the final assembled video

**Voice never cuts. B-roll swaps visuals only.** The wrong approach (stitch all clips then add voice) breaks timing because B-roll adds visual duration that doesn't exist in the voice track.

For single-clip talking head: Sora's built-in audio may be sufficient. For podcast format: always use ElevenLabs S2S.

### Multi-Clip Stitching

For longer UGC, either use fal.ai's 20s duration or stitch clips:

**Last-frame stitching (tested, works well):**
1. Extract last frame: `ffmpeg -sseof -0.1 -i clip1.mp4 -frames:v 1 last-frame.png`
2. Use as first frame of clip 2 → seamless visual continuity
3. Concatenate with ffmpeg

```bash
bash scripts/extend-clip.sh \
  --input campaigns/<slug>/clips/clip-01.mp4 \
  --prompt-file campaigns/<slug>/extension-prompt.txt \
  --output campaigns/<slug>/clips/clip-01-extended.mp4 \
  --seconds 10
```

Use `scripts/stitch-video.sh` for resolution normalization. Read `references/voice-system.md` for voice design guidance.

## Stage 2: Post-Production (mandatory)

Raw AI output → post-production → final asset. Never skip.

Use `scripts/post-production.sh` for automated color grade, grain, and frame rate normalization.

Read `references/post-production.md` for the full realism stack: color grade, grain (the 4K upscale trick), skin texture, frame rate lock, audio realism, lighting consistency.

If mixing Sora + Kling clips, pay special attention to cross-engine color matching — see `references/orchestrator.md` (in `b-roll/references/`).

**The phone test:** watch the final video on a phone screen, in the app, scrolling past it like a user. If anything pings as AI, fix it.

Read `references/green-zone.md` for platform safe zones.

## Stage 3: Captions (ALWAYS LAST)

**⚠️ Captions MUST be applied AFTER post-production, not before.** Grain and color grade degrade clean caption pills.

```bash
# Auto-detect video resolution and generate matching caption overlay
/usr/bin/python3 scripts/generate-caption.py \
  --video clips/post-produced.mp4 \
  --lines "when your gym software,cannot even handle,a data migration..." \
  --output frames/caption.png

# Overlay onto post-produced video
/usr/bin/ffmpeg -i clips/post-produced.mp4 -i frames/caption.png \
  -filter_complex "[0:v][1:v]overlay=0:0:enable='between(t,0.2,3.8)'" \
  -c:v libx264 -preset fast -crf 18 -c:a copy clips/final.mp4
```

**Critical:** caption PNG must match EXACT video resolution. Use `--video` flag to auto-detect. Mismatched resolutions cause off-center captions.

Style: Inter SemiBold, white pills per line, #0A1931 text, 15px radius, auto-scaled to video resolution.

Resolution note: Sora outputs 720x1280, Kling outputs 1076x1924. Always normalize to one resolution before stitching.

Requires `/usr/bin/ffmpeg` (apt version with libfreetype) and `/usr/bin/python3` with PIL.

## Brand Memory Integration

### Reads
| File | Purpose |
|------|---------|
| `workspace/campaigns/<slug>/clips/*.mp4` | All A-roll and B-roll clips to assemble |
| `workspace/campaigns/<slug>/scripts/<format>-script.md` | Timing, B-roll insertion points, caption text |
| `workspace/campaigns/<slug>/creators/creator-<name>.md` | Voice reference for ElevenLabs S2S voice design |
| `workspace/creators/creator-<name>.md` | Fallback if no campaign-specific profile exists |

### Writes
| File | Notes |
|------|-------|
| `workspace/campaigns/<slug>/clips/final-<version>.mp4` | Assembled video with voice, post-production, captions |
| `workspace/campaigns/<slug>/output-log.md` | Assembly params, S2S voice used, ffmpeg settings (append-only) |

### Context loading

```
🔧 Assemble context loaded:
  ✓ Campaign: ridge-q1
  ✓ A-roll clips: 3 (workspace/campaigns/ridge-q1/clips/a-roll-*.mp4)
  ✓ B-roll clips: 2 (workspace/campaigns/ridge-q1/clips/b-roll-*.mp4)
  ✓ Script: talking-head (workspace/campaigns/ridge-q1/scripts/talking-head-script.md)
  ✓ Creator voice profile: Maya
```

## Output

- Final assembled video (MP4) in `workspace/campaigns/<slug>/clips/final-<version>.mp4`
- All intermediate files preserved in `workspace/campaigns/<slug>/`
- Assembly params logged to `workspace/campaigns/<slug>/output-log.md`

## Next Step

Assembly complete → run `/score` to verify virality score before publishing.
