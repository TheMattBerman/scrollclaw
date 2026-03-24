---
name: scrollclaw
description: "Router and orchestrator for AI UGC video production. Use for broad outcome requests like making a UGC video or running a campaign; it routes step-specific requests to the right sub-skill and can drive the full pipeline from persona research through virality-scored video."
metadata:
  openclaw:
    emoji: "🎬"
    user-invocable: true
    triggers:
      - "scrollclaw"
      - "ugc video"
      - "ai ugc"
      - "make ugc"
      - "ugc campaign"
      - "ugc pipeline"
      - "talking head video"
      - "product review video"
      - "start ugc"
---

# ScrollClaw

AI-generated UGC videos that look like a real person pulled out their phone and started talking. Brands pay $500–$5,000 per UGC video from human creators. This pipeline produces them for $5–$50 in API costs.

## The Pipeline

```
Brand + Audience
      ↓
/persona    → Persona research, creator profiles, approved script
/first-frame → Canonical face image (Nano Banana 2)
/animate    → A-roll talking head clips (Sora 2 i2v)
/b-roll     → Environment + product shots (Kling 3)
/assemble   → Stitch + unified voice + post-production + captions
/score      → Virality gate (70+ to publish)
      ↓
Scroll-stopping UGC video
```

**Core doctrine:** Read `_system/SKILL.md` for format selection, anti-patterns, taste calibration, and pipeline routing rules.

**Brand & campaign context:** Read `_system/references/brand-campaign-context.md` for workspace structure, context matrix, and persistence protocol.

---

## Routing

When the user invokes ScrollClaw or asks about UGC video, route to the right sub-skill based on where they are in the pipeline:

| User says / wants | Route to |
|-------------------|----------|
| "Make me a UGC video" / "Start a campaign" / "I need ugc" | `/persona` — start at the beginning |
| "Research this brand" / "Create a creator profile" / "Write a script" | `/persona` |
| "Generate the first frame" / "Make a face image" / "Nano Banana" | `/first-frame` |
| "Animate this" / "Make a talking head clip" / "Sora" / "A-roll" | `/animate` |
| "Generate B-roll" / "Product shot" / "Kling" | `/b-roll` |
| "Stitch the clips" / "Add captions" / "Post-production" / "Assemble" | `/assemble` |
| "Score this video" / "Is this ready to publish?" | `/score` |
| "Run the full pipeline" | Start at `/persona`, proceed sequentially |

Broad outcome requests stay at the root. Start the pipeline instead of asking the user to pick a sub-skill.

Stage-specific requests bypass the root and go straight to that sub-skill.

If the user isn't sure where they are, ask: **"Where are you in the pipeline?"** and show them the 6 steps above.

## Contract

### Input
- Required: brand/product context plus a campaign goal, or an existing campaign workspace if resuming
- Optional: format preference, creator profile, screen recordings/screenshots, existing clips, campaign slug
- Format: raw text, URL, file paths, or `workspace/campaigns/<slug>/` files
- Source: user prompt, campaign brief, and upstream `workspace/brand/` files

### Output
- Produces: either a route decision to the correct stage or a sequential full-pipeline run starting at `/persona`
- Format: inline orchestration plus saved workspace artifacts produced by sub-skills
- Default behavior: broad requests like "make me a UGC video" or "start a campaign" start at `/persona` and continue stage by stage until blocked by missing inputs, an approval gate, or a dependency failure
- Downstream use: `/persona`, `/first-frame`, `/animate`, `/b-roll`, `/assemble`, and `/score`

### Validation
- Pre-conditions: workspace exists or can be initialized before generation steps begin
- Post-conditions: the user knows the current stage, the next stage, and which workspace artifacts were produced
- Failure checks: do not leave the user at a vague route; if blocked, name the exact missing file, asset, or approval needed

---

## Quick Start

**First campaign:**
1. Initialize workspace:
   ```bash
   CAMPAIGN="my-campaign"
   mkdir -p workspace/campaigns/$CAMPAIGN/{creators,scripts,frames,clips,scores}
   cp assets/campaign-brief-template.md workspace/campaigns/$CAMPAIGN/brief.md
   touch workspace/campaigns/$CAMPAIGN/output-log.md
   touch workspace/campaigns/$CAMPAIGN/learnings.md
   ```
2. Fill in `workspace/campaigns/$CAMPAIGN/brief.md`
3. Run `/persona` → `/first-frame` → `/animate` → `/b-roll` → `/assemble` → `/score`

**Check setup first:**
```bash
bash scripts/check-deps.sh
```

---

## What ScrollClaw Needs

| Key | Required | Used by |
|-----|----------|---------|
| `FAL_KEY` | Yes | Sora 2 (A-roll) + Kling 3 (B-roll) |
| `REPLICATE_API_TOKEN` | Yes | Nano Banana (first frames) |
| `OPENROUTER_API_KEY` | Recommended | Gemini (virality scoring) |
| `ELEVENLABS_API_KEY` | Optional | Multi-clip voice consistency (S2S) |

---

## Six Formats

| Format | Duration | Best for |
|--------|----------|---------|
| Talking Head | 15-25s | Product review, honest take |
| Hook Face + Demo | 15s max | App/tool demos |
| Podcast Clip | 8-20s | Authority, credibility |
| Wall of Text | 4-8s | Hot take, faceless |
| Visual Transformation | 10-25s | Before/after concept |
| Hybrid Transformation | 20-30s | Complex mechanism explanation |

---

## Key Findings (from testing)

- Sora's native voice > ElevenLabs TTS for talking head. TTS sounds fake.
- B-roll must be environment-matched. Extract a frame from A-roll → feed to Kling.
- Captions go LAST — after post-production. Grain degrades caption pills.
- AI cannot generate realistic app screens. Use real screenshots.
- ~1 in 3 Sora generations have hand artifacts. Reroll, don't fix the prompt.
- Multi-frame formats: chain from frame 1. Parallel generation causes face drift.

---

For full doctrine, format blueprints, anti-patterns, and taste calibration: [`_system/SKILL.md`](_system/SKILL.md)
