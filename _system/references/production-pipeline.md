# Production Pipeline — Strict Order

Every ScrollClaw production follows this sequence. No exceptions. Skipping steps or reordering causes the exact problems documented in session learnings.

## Pre-Flight

```bash
bash scripts/pre-flight.sh <campaign-slug>
```

All checks must pass before generating anything. The script validates:
- Campaign workspace and directory structure
- Creator profile loaded
- Reference image exists for i2v
- Script with segment mapping
- Caption plan (text + timing for every scene)
- Text style parameters set

**If pre-flight fails, fix it before touching any generation API.**

## Step 1: Generate First Frames

Source: creator reference image via Nano Banana 2

```
Reference image → Nano Banana 2 → first-frame PNG
```

**NEVER text-to-image of random people.** The creator system exists to lock identity. Every first frame must be generated from the creator's canonical reference image. Random generation wastes tokens and produces unusable output.

## Step 2: Submit i2v Clips

Source: first-frame PNGs → Sora 2 image-to-video

```
First-frame PNG → Sora 2 i2v → A-roll clip
```

**NEVER text-to-video for established creators.** t2v generates a different person every time. Always i2v from the reference. The only exception is the very first exploration of a new creator concept before a reference is locked.

Parallel submission is fine — fire all clips at once for speed. But chain from the same reference image for face consistency.

## Step 3: Download and QA Each Clip

Download every clip immediately (Replicate URLs are ephemeral). Then QA each individually:

- Extract thumbnails at multiple timestamps
- Send to Gemini Flash for frame-by-frame content drift check
- Look for: wrong person appearing, hand artifacts, scene drift

```bash
bash scripts/qa-check.sh workspace/campaigns/<slug>/clips/a-roll-01.mp4
```

Fix problems now. Re-rolling a single clip is cheap. Re-rolling after stitch is expensive.

## Step 4: Stitch Clips

Use last-frame stitching for visual continuity:

```bash
bash scripts/stitch-video.sh \
  workspace/campaigns/<slug>/clips/a-roll-01.mp4 \
  workspace/campaigns/<slug>/clips/a-roll-02.mp4 \
  --output workspace/campaigns/<slug>/clips/stitched.mp4
```

Normalize resolution before stitching (Sora = 720x1280, Kling = 1076x1924).

## Step 5: Post-Production

Color grade, audio normalization, grain, vignette — the realism pass.

```bash
bash scripts/post-production.sh \
  workspace/campaigns/<slug>/clips/stitched.mp4 \
  --output workspace/campaigns/<slug>/clips/post-produced.mp4
```

**Post-production MUST happen before captions.** Grain degrades caption text. Color grading shifts caption colors. Always: raw → stitch → post-produce → THEN captions.

## Step 6: Burn Captions/Overlays LAST

Generate overlay PNG with the caption-overlay system:

```bash
python3 assemble/scripts/caption-overlay.py \
  --video workspace/campaigns/<slug>/clips/post-produced.mp4 \
  --preset tiktok-wall \
  --lines "things i didn't know,would bother me about,my boyfriend..." \
  --output workspace/campaigns/<slug>/frames/caption.png
```

Composite onto post-produced video:

```bash
ffmpeg -i post-produced.mp4 -i caption.png \
  -filter_complex "[0:v][1:v]overlay=0:0:enable='between(t,0.2,3.8)'" \
  -c:v libx264 -profile:v main -pix_fmt yuv420p -crf 18 \
  -movflags +faststart -c:a copy final.mp4
```

**Caption PNG must match exact video resolution.** Use `--video` flag for auto-detection.

## Step 7: Final QA

```bash
bash scripts/qa-check.sh workspace/campaigns/<slug>/clips/final-v1.mp4
```

Verify:
- Codec: h264, yuv420p, main profile
- Every caption appears at correct timestamp
- No content drift across scenes
- Duration and resolution correct
- Send final frame extracts to Gemini Flash for one last check

## Step 8: Compress with Compatible Encoding

If the final encode isn't already compatible, re-encode:

```bash
ffmpeg -i final.mp4 \
  -c:v libx264 -profile:v main -pix_fmt yuv420p \
  -crf 23 -preset medium \
  -movflags +faststart \
  -c:a aac -b:a 128k -ar 44100 \
  delivery.mp4
```

**These encoding defaults are non-negotiable.** `yuv444p` or `High 4:4:4 Predictive` profile breaks Telegram Web, many mobile browsers, and some social platforms. Always `yuv420p` + `main` profile + `faststart`.

---

## Quick Reference

| Step | Tool | Key Rule |
|------|------|----------|
| Pre-flight | `scripts/pre-flight.sh` | All checks pass before generating |
| First frames | Nano Banana 2 | ALWAYS from reference image |
| A-roll | Sora 2 i2v | NEVER t2v for established creators |
| QA clips | `scripts/qa-check.sh` + Flash | Check EVERY clip for drift |
| Stitch | `scripts/stitch-video.sh` | Normalize resolution first |
| Post-produce | `scripts/post-production.sh` | BEFORE captions |
| Captions | `assemble/scripts/caption-overlay.py` | AFTER post-production, LAST step |
| Final QA | `scripts/qa-check.sh` + Flash | One last check before delivery |
| Encode | ffmpeg | yuv420p, main, faststart — always |
