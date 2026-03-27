---
name: scrollclaw-assemble
description: "Assembly stage for UGC videos. Handles stitch mode, post mode, captions mode, or full-assemble mode when the user is explicitly working on finalizing an existing campaign video."
metadata:
  openclaw:
    emoji: "🔧"
    user-invocable: true
    triggers:
      - "assemble video"
      - "full assemble"
      - "stitch clips"
      - "post production"
      - "post produce video"
      - "add captions"
      - "burn captions"
      - "caption overlay"
      - "ugc captions"
      - "ugc audio"
      - "ugc post-production"
---

# Assemble

Three stages: stitch + audio → post-production → captions. Order matters.

## Modes

This skill handles four intents. Choose the narrowest one that matches the user's request:

- `stitch` — timeline assembly and voice orchestration only
- `post` — post-production realism pass only
- `captions` — caption rendering and overlay only
- `full-assemble` — do all three in order; this is the default when the user says "assemble", "finish the video", or otherwise asks for the final output

If the user asks for one stage explicitly, do not force the full pipeline. If they ask for the final video, run `full-assemble`.

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
  --input workspace/campaigns/<slug>/clips/a-roll-01.mp4 \
  --prompt-file workspace/campaigns/<slug>/extension-prompt.txt \
  --output workspace/campaigns/<slug>/clips/a-roll-01-extended.mp4 \
  --log-file workspace/campaigns/<slug>/output-log.md \
  --label a-roll-01-extended \
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

**⚠️ Captions MUST be applied AFTER post-production, not before.** Grain and color grade degrade clean caption text. This was the #1 process mistake in session 2.

### Caption Overlay System

Use `assemble/scripts/caption-overlay.py` for all text overlays. It generates transparent PNGs with TikTok-native styling, auto-detects video resolution, and downloads TikTok Sans from Google Fonts if not cached.

```bash
# Generate caption overlay (auto-detects resolution from video)
python3 assemble/scripts/caption-overlay.py \
  --video workspace/campaigns/<slug>/clips/post-produced.mp4 \
  --preset tiktok-wall \
  --lines "things i didn't know,would bother me about,my boyfriend..." \
  --output workspace/campaigns/<slug>/frames/caption.png

# Overlay onto post-produced video (with compatible encoding)
ffmpeg -i workspace/campaigns/<slug>/clips/post-produced.mp4 \
  -i workspace/campaigns/<slug>/frames/caption.png \
  -filter_complex "[0:v][1:v]overlay=0:0:enable='between(t,0.2,3.8)'" \
  -c:v libx264 -profile:v main -pix_fmt yuv420p -crf 18 \
  -movflags +faststart -c:a copy \
  workspace/campaigns/<slug>/clips/final-01.mp4
```

### Approved TikTok Text Presets

| Preset | Use For | Font | Size | Color | Stroke |
|--------|---------|------|------|-------|--------|
| `tiktok-wall` | Wall of Text format, dense overlays | TikTok Sans Regular | 38px | #F7F7F2 94% opacity | 2.5px pure black |
| `tiktok-hook` | Hook captions, opening text | TikTok Sans Bold | 52px | #FFFFFF 100% | 3px pure black |
| `tiktok-scene` | Scene-by-scene captions | TikTok Sans Regular | 32px | #F7F7F2 94% opacity | 2px pure black |
| `tiktok-dense` | Dense multi-line overlays | TikTok Sans Regular | 28px | #F7F7F2 94% opacity | 2px pure black |

All presets use centered alignment and safe zone positioning (y=280 at 720x1280 base). Values scale automatically for other resolutions.

### Full control via JSON config

For per-scene caption configs, pass a JSON file:

```bash
python3 assemble/scripts/caption-overlay.py \
  --config workspace/campaigns/<slug>/scripts/captions.json \
  --output workspace/campaigns/<slug>/frames/caption-s1.png
```

### Legacy pill-style captions

The older `scripts/generate-caption.py` still supports pill-style (white rounded rect background) and wall-style captions using Inter font. Use `assemble/scripts/caption-overlay.py` for all new work — it has the correct TikTok-native styling.

### Caption rules

- **Caption PNG must match EXACT video resolution.** Use `--video` flag to auto-detect.
- **Use PIL for text overlays** — more control than ffmpeg drawtext, no escaping issues.
- **Use textfile approach** if ffmpeg drawtext is ever needed (avoids apostrophe/escaping bugs).
- **Visual Transformation format requires captions on EVERY scene**, not just the hook.
- **No background pills** for TikTok-native text — stroke only.
- **Always encode with compatible defaults** after caption burn: `-profile:v main -pix_fmt yuv420p -movflags +faststart`

Resolution note: Sora outputs 720x1280, Kling outputs 1076x1924. Always normalize to one resolution before stitching.

Requires `ffmpeg` and `python3` with Pillow (auto-installed if missing).

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

## Contract

### Input
- Required: A-roll clips plus a timing-aware script
- Optional: B-roll clips, creator voice profile, ElevenLabs S2S settings
- Format: workspace video files, script markdown, and optional voice metadata
- Source: `/animate`, `/b-roll`, `/persona`, and `references/audio-orchestration.md`

### Output
- Produces: one assembled final video with stitched visuals, audio, post-production, and captions
- Format: `final-<version>.mp4` in `workspace/campaigns/<slug>/clips/` plus append-only assembly logs
- Default behavior: stitch A-roll first, apply voice orchestration, insert B-roll as visual-only cuts, run post-production, then add captions last
- Downstream use: `/score`

### Validation
- Pre-conditions: source clips exist, script timing is usable, and all inputs are normalized enough to assemble
- Post-conditions: final video is saved locally, voice stays continuous, and captions sit on the post-produced file rather than the raw render
- Failure checks: fix resolution mismatches, broken timing, or synthetic-looking audio here before handing anything to `/score`

### Stage checkpoints
- `stitch`: assembled timeline exists, cuts land on script beats, voice continuity holds across A-roll and B-roll
- `post`: post-produced file exists, mixed-engine clips look visually coherent, phone test does not immediately ping as AI
- `captions`: caption overlay matches exact video resolution, readability is mobile-safe, and captions were applied after post-production

## Output

- Final assembled video (MP4) in `workspace/campaigns/<slug>/clips/final-<version>.mp4`
- All intermediate files preserved in `workspace/campaigns/<slug>/`
- Assembly params logged to `workspace/campaigns/<slug>/output-log.md`

## Next Step

Assembly complete → run `/score` to verify virality score before publishing.
