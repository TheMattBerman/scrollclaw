---
name: scrollclaw
description: "AI UGC video production suite. Six sub-skills that take a brand from persona research through virality-scored video. Produces talking head, podcast clip, hook face + demo, wall of text, visual transformation, and hybrid transformation formats."
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

If the user isn't sure where they are, ask: **"Where are you in the pipeline?"** and show them the 6 steps above.

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
