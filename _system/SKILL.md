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
| 0. Brand setup (one-time) | `/brand-setup` | Research brand, generate voice/positioning/audience files |
| 1. Persona research | `/persona` | Mine reviews, extract real language |
| 2. Brand context | `/persona` | Load brand voice, know the product |
| 3. Creator profiles | `/persona` | Lock identity in `workspace/campaigns/<slug>/creators/` or `workspace/creators/` |
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

Read `references/taste-calibration.md` for before/after examples that show what "anti-polish" actually sounds and looks like in practice.

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
├── brand/                    ← Read-only for ScrollClaw (written by /brand-setup, GrowthClaw, or manually)
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
| `/brand-setup` | Brand website, social profiles, reviews, competitors (scraped) | `brand/voice-profile.md`, `brand/positioning.md`, `brand/audience.md` |
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
- Creator profiles: global ones go in `workspace/creators/`, campaign overrides in `workspace/campaigns/<slug>/creators/`
- Skills own their outputs. `/persona` owns `persona-research.md`. `/score` owns `scores/` and `learnings.md`.

## Common Mistakes (from live production sessions)

These mistakes have been made in real sessions. Every one of them wasted time and tokens. Do not repeat them.

### Never generate random people — always use creator reference

The creator system exists to lock visual identity. Every first frame must be generated from the creator's canonical reference image using i2v. Generating 7 random people instead of using Jess's locked reference was the biggest waste in session 2.

**Wrong:** text-to-image → random person → animate
**Right:** reference image → Nano Banana 2 → first frame → Sora 2 i2v

### Never use text-to-video for established creators — always i2v

t2v generates a completely different person every time. Once a creator has a reference image, always use image-to-video. The only acceptable use of t2v is initial exploration before a reference is locked.

### Never caption before post-production

Grain degrades caption text. Color grading shifts caption colors. The order is non-negotiable:

```
raw clips → stitch → post-produce → THEN captions (LAST)
```

### Always QA with vision model after stitch

Use Gemini Flash to scrub every clip frame-by-frame after stitching. It catches content drift (wrong person appearing mid-clip), hand artifacts, and scene inconsistencies that are easy to miss on a quick watch. Don't wait for the user to catch problems.

### Always use compatible encoding defaults

```bash
-c:v libx264 -profile:v main -pix_fmt yuv420p -crf 23 -preset medium -movflags +faststart -c:a aac -b:a 128k -ar 44100
```

`yuv444p` and `High 4:4:4 Predictive` profile break Telegram Web, many mobile browsers, and some social platforms. Always `yuv420p` + `main` profile + `faststart`. Do this from the first encode, not as a fix after delivery fails.

### Always run pre-flight before generating

```bash
bash scripts/pre-flight.sh <campaign-slug>
```

Validates workspace structure, creator profiles, reference images, scripts, and caption plans. Catches missing prerequisites before you waste API calls.

### Follow the production pipeline order

Read `references/production-pipeline.md` for the strict step-by-step sequence. Every step depends on the previous one being done correctly.

## Setup
Run `scripts/check-deps.sh` to verify all API keys and dependencies.
