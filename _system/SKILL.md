---
name: _scrollclaw-system
description: "ScrollClaw system — core doctrine, format selection, pipeline routing, and anti-patterns. Loaded into every UGC conversation."
metadata:
  openclaw:
    always: true
    user-invocable: false
    emoji: "🎬"
---

# ScrollClaw System

AI video defaults to cinematic. Sweeping drone shots. Perfect lighting. Orchestral energy. Nobody scrolls past that thinking "real person" — they think "ad" and keep moving. UGC works because it looks like someone pulled out their phone and talked.

## Core Doctrine

**Messaging is the actual skill.** The tools improve weekly — visuals, voice, motion are getting solved. AI cannot solve having something worth saying. Most AI UGC fails not because it looks like AI but because the script sounds like a copywriter, not a customer. Persona research before production. Real language before prompts.

**Anti-polish is the product.** Every decision optimizes for "could a real person have shot this on their phone." Impressive is the enemy.

**Creators are persistent.** AI creators have locked identities — same face, same hair, same build across every clip. First-frame consistency: generate one canonical face with Nano Banana, feed it to every Sora/Kling i2v generation. Read `references/creator-system.md`.

**First frame controls everything.** Generate frame 1 with Nano Banana 2 (composition, character, environment, color locked), then animate with Sora 2 i2v. Text-to-video is the fallback.

**Save first, watch later.** Replicate URLs are ephemeral. Every output gets downloaded immediately.

**System not clip.** Every run leaves reusable creator profiles, prompt logs, color references. Campaign 10 takes a fraction of campaign 1.

## The Six Dimensions

Setting. Cadence. Influencer realism. Story. Product. Audience. Every decision routes through these. Most people skip consumer psychology — that's why their AI looks obvious.

## Format Selection

Ask: **what are we making?** Then route to the right format.

| If the goal is... | Format | What user provides | What AI generates |
|-------------------|--------|-------------------|-------------------|
| Product review / honest take | Talking Head | Brand context | Everything (face, voice, video) |
| App/tool demo (scroll-stopper) | Hook Face + Demo | **Screen recording** (recommended) or screenshots | Hook face + captions. Demo = real footage. |
| Authority / credibility | Podcast Clip | Brand context | Everything (face, set, voice) |
| Quick visual transformation | Visual Transformation | Brand context, before/after concept | All imagery + animation |
| Complex mechanism explanation | Hybrid Transformation | Brand context, deep persona research | Talking head bookends + slideshow |
| Hot take / faceless | Wall of Text | The text content | Static image + text overlay |

Read `references/format-library.md` for shot-by-shot blueprints. Read `references/hook-emotions.md` for the emotion taxonomy.

## Pipeline Overview

| Step | Skill | What happens |
|------|-------|-------------|
| 1. Persona research | `/persona` | Mine reviews, extract real language |
| 2. Brand context | `/persona` | Load brand voice, know the product |
| 3. Creator profiles | `/persona` | Lock identity in `creators/` |
| 4. Format + Script | `/persona` | Choose format, write script with visual beats |
| 5. First frame | `/first-frame` | Nano Banana 2 → canonical face image |
| 6. Animate (A-roll) | `/animate` | Sora 2 i2v → talking head clips |
| 7. B-roll | `/b-roll` | Kling 3 → environment/product shots |
| 8. Stitch + Audio | `/assemble` | Multi-clip stitching, ElevenLabs S2S voice |
| 9. Post-production | `/assemble` | Color grade, grain, frame rate, phone test |
| 10. Captions | `/assemble` | Native-style caption overlays (LAST step) |
| 11. Score | `/score` | Virality scoring — 70+ to publish |

## Anti-Patterns

**Visual:** Cinematic drift (override with handheld energy), model-pretty creators (specify normal-looking), clean room syndrome (demand real clutter), porcelain skin (specify visible pores), smooth steadicam (phone has micro-shake).

**Color:** Grey-scale Nano Banana default (fix with JSON color prompts). Too-clean color (lift shadows, slight fade). See `references/color-reference-system.md`.

**Audio:** Clean studio audio (add room ambience). Library ElevenLabs voices (voice design or instant clone only). Stock music (real UGC rarely has music).

**Script:** Testimonial cadence ("I've been using this for three weeks..."). Wardrobe drift across same-day clips.

**Pipeline:** Output loss (download immediately). Hallucinated text (add "no text" to negative prompt). Extra limbs (reroll, don't fix prompt). Resolution mismatch (normalize before stitching). Multi-clip voice drift (use ElevenLabs S2S).

## Taste Calibration

**Bad prompt:** "A young woman enthusiastically reviewing a skincare product in a bright, modern bathroom"

**Good prompt:** "A woman, age 26-30, slightly tired eyes, messy bun, oversized t-shirt, sitting cross-legged on an unmade bed, holding a small amber bottle close to camera, natural window light from the left, phone propped on a stack of books at slightly off-center angle, room has visible nightstand clutter — water glass, phone charger, hair tie — iPhone selfie-camera realism, not steady, not composed"

**Bad script:** "I've been using this serum for two weeks now and I have to say, the results have been incredible."

**Good script:** "okay so. I bought this like two weeks ago because someone on tiktok wouldn't shut up about it and I was like whatever. but um. look at this. [holds bottle up] like my dark spots are actually... they're not gone but they're definitely lighter? I don't know. I'm kind of annoyed it actually works because it's not cheap."

## Contract

**Input:** product/brand context (URL, description, or brand voice file). Optional: creator profiles, format preference, color references.

**Output:** video clips (MP4), first-frame images (PNG), creator profiles, scripts, prompt logs. Default 9:16 vertical.

**Env:** FAL_KEY (primary), REPLICATE_API_TOKEN (Nano Banana + fallback), ELEVENLABS_API_KEY (multi-clip voice), OPENROUTER_API_KEY (Gemini virality scoring).

## Brand & Campaign Context

ScrollClaw persists work across sessions using a structured workspace. Campaign 10 takes a fraction of campaign 1 because creator profiles, brand context, and learnings accumulate.

**Full protocol:** Read `references/brand-campaign-context.md`.

### Workspace structure

```
workspace/
├── brand/                    ← Read-only for ScrollClaw (written by GrowthClaw etc.)
│   ├── voice-profile.md      ← Brand voice → informs script tone
│   ├── positioning.md        ← Differentiation → informs persona research
│   └── audience.md           ← ICP → informs creator archetype selection
├── creators/                 ← Global creator profiles (reusable across campaigns)
└── campaigns/<slug>/
    ├── brief.md              ← Campaign brief (from assets/campaign-brief-template.md)
    ├── persona-research.md   ← Written by /persona
    ├── creators/             ← Campaign-specific creator overrides
    ├── scripts/              ← Approved scripts
    ├── frames/               ← First frames + context frames
    ├── clips/                ← A-roll, B-roll, assembled finals
    ├── scores/               ← Virality score cards
    ├── output-log.md         ← Prompt log, generation params (append-only)
    └── learnings.md          ← What worked, what didn't (append-only)
```

### Context matrix

| Skill | Reads | Writes |
|-------|-------|--------|
| `/persona` | `brand/{voice-profile,positioning,audience}.md`, campaign brief | `persona-research.md`, `creators/`, `scripts/` |
| `/first-frame` | `creators/`, `scripts/`, campaign brief | `frames/`, `output-log.md` |
| `/animate` | `frames/`, `scripts/`, `creators/` | `clips/a-roll-*.mp4`, `output-log.md` |
| `/b-roll` | `frames/`, `clips/a-roll-*`, `scripts/` | `clips/b-roll-*.mp4`, `output-log.md` |
| `/assemble` | `clips/*`, `scripts/`, `creators/` | `clips/final-*.mp4`, `output-log.md` |
| `/score` | `clips/final-*`, campaign brief, `persona-research.md` | `scores/`, `learnings.md` |

### Rules for reading brand memory

- Check if each brand file exists before reading. Never error on missing files.
- Show what was loaded: `✓ Loaded brand voice: conversational-direct` / `✗ No audience file — proceeding standalone`
- ScrollClaw reads `workspace/brand/` but **never writes** there

### Rules for writing campaign files

- `output-log.md` and `learnings.md` are **append-only** — never overwrite
- Creator profiles: global ones go in `workspace/creators/`, campaign overrides in `campaigns/<slug>/creators/`
- Skills own their outputs. `/persona` owns `persona-research.md`. `/score` owns `scores/` and `learnings.md`.

## Setup
Run `scripts/check-deps.sh` to verify all API keys and dependencies.
