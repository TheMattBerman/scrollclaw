```
███████╗ ██████╗ ██████╗  █████╗     ██╗   ██╗ ██████╗  ██████╗
██╔════╝██╔═══██╗██╔══██╗██╔══██╗    ██║   ██║██╔════╝ ██╔════╝
███████╗██║   ██║██████╔╝███████║    ██║   ██║██║  ███╗██║     
╚════██║██║   ██║██╔══██╗██╔══██║    ██║   ██║██║   ██║██║     
███████║╚██████╔╝██║  ██║██║  ██║    ╚██████╔╝╚██████╔╝╚██████╗
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝     ╚═════╝  ╚═════╝  ╚═════╝
```

**AI-generated UGC videos that look like a real person pulled out their phone and started talking.**

Brands pay $500–$5,000 per UGC video from human creators. This skill produces them for $5–$50 in API costs.

---

## The big idea

Most AI video looks like AI video. Cinematic drone shots. Perfect lighting. Orchestral energy. Nobody scrolls past that thinking "real person" — they think "ad" and keep moving.

UGC works because it looks like someone pulled out their phone and talked.

This skill makes AI produce that.

Not by adding filters after. By building the entire pipeline around anti-polish: persona research that steals real customer language, first frames that look like iPhone photos, motion prompts that produce handheld energy, audio that sounds like a kitchen not a studio, and post-production that adds grain instead of removing it.

---

## What it produces

```
Brand + Audience
      ↓
┌─────────────────────────────┐
│  1. Persona research        │  ← mines real reviews for exact language
│  2. Creator profile         │  ← persistent AI "creator" with locked identity
│  3. Format + script         │  ← 6 formats with shot-by-shot enforcement
│  4. First frame (Nano Banana)│  ← iPhone-realistic, not AI-looking
│  5. A-roll (Sora 2)        │  ← talking head with synced voice + lip sync
│  6. B-roll (Kling 3)       │  ← fast contextual scenes, env-matched
│  7. Audio orchestration     │  ← native voice, continuous over B-roll
│  8. Post-production         │  ← color grade, grain, frame rate
│  9. Captions                │  ← native platform-style overlays
│ 10. Virality scoring        │  ← 7-criteria gate, only 70+ publishes
└─────────────────────────────┘
      ↓
Scroll-stopping UGC video
```

## 6 formats

| Format | What it is | Duration |
|--------|-----------|----------|
| **Talking Head** | One person, one camera, honest review | 15-25s |
| **Hook Face + Demo** | Emotive face stops scroll → product demo | 15s max |
| **Podcast Clip** | Fake podcast guest — mic, headphones, authority | 8-20s |
| **Wall of Text** | Animated person + dense text overlay | 4-8s |
| **Visual Transformation** | Named concept ("The Scroll Trap") + before/after | 10-25s |
| **Hybrid Transformation** | Talking head bookends + slideshow mechanism bridge | 20-30s |

## What you need

### API keys

| Key | Required | What it does |
|-----|----------|-------------|
| `FAL_KEY` | Yes | Sora 2 (talking head video) + Kling 3 (B-roll) via fal.ai |
| `REPLICATE_API_TOKEN` | Yes | Nano Banana (first frame image generation) |
| `OPENROUTER_API_KEY` | Recommended | Gemini via OpenRouter (virality scoring + analysis) |
| `ELEVENLABS_API_KEY` | Optional | Only for multi-clip voice consistency (S2S) |

Get keys: [fal.ai](https://fal.ai/dashboard/keys) · [Replicate](https://replicate.com/account/api-tokens) · [OpenRouter](https://openrouter.ai/keys) · [ElevenLabs](https://elevenlabs.io/app/settings/api-keys)

### System requirements

- **Python 3** with PIL (`sudo apt install python3-pil`)
- **ffmpeg** with libfreetype (`sudo apt install ffmpeg` — NOT the Homebrew version)
- **Inter font** (auto-downloaded by the dependency checker)

### Check everything

```bash
bash scripts/check-deps.sh
```

## Quick start — your first video in 20 minutes

1. **Run the dependency check** to make sure everything's configured
2. **Tell the skill what brand and who the audience is** — it handles persona research
3. **Pick a format** — the skill recommends one based on your goal
4. **Approve the script** — it writes one mapped to the format's shot breakdown
5. **Generate the first frame** — review it before committing to video
6. **Generate video + B-roll** — Sora for talking head, Kling for B-roll scenes
7. **Post-production + captions** — automated color grade, grain, caption overlay
8. **Virality score** — only publish if it scores 70+

## Key findings from testing

- **Sora's native voice is always better than ElevenLabs TTS** for talking head. TTS sounds fake. Sora does voice + lip sync together.
- **B-roll must be environment-matched.** Extract a frame from the A-roll → feed to Kling. Generic B-roll looks like stock footage.
- **Captions go LAST** — after post-production. Grain degrades caption pills.
- **AI cannot generate realistic UI/app screens.** Use real screenshots for demos.
- **Describe audio by how it sounds, not the gear.** "Clean, natural, close and present" works. "Shure SM7B" doesn't.
- **~1 in 3 Sora generations have hand artifacts.** Reroll, don't fix the prompt.
- **Multi-frame formats: chain from frame 1.** Generate the canonical face first, then reference it for every subsequent frame. Parallel generation causes face drift.

## Evaluation

- Baseline comparison: [`evals/baseline-vs-scrollclaw.md`](evals/baseline-vs-scrollclaw.md)
- Execution checks: [`evals/execution-evals.md`](evals/execution-evals.md)
- Trigger checks: [`evals/trigger-evals.md`](evals/trigger-evals.md)

## Architecture

```
scrollclaw/
├── SKILL.md                    Router — orchestrates the full suite
├── README.md                   You are here
├── _system/                    Shared doctrine + context protocol
│   ├── SKILL.md                Core doctrine, format selection, pipeline routing
│   └── references/
│       ├── brand-campaign-context.md   Brand memory + campaign workspace protocol
│       ├── color-reference-system.md
│       ├── creator-system.md
│       ├── format-library.md
│       ├── hook-emotions.md
│       └── taste-calibration.md
├── persona/                    Step 1: Persona research + scripting
│   ├── SKILL.md
│   └── references/
│       ├── persona-research.md
│       └── script-voice.md
├── first-frame/                Step 2: Canonical frame generation
│   ├── SKILL.md
│   └── references/
│       ├── first-frame-prompting.md
│       └── first-frame-psychology.md
├── animate/                    Step 3: A-roll (Sora 2)
│   ├── SKILL.md
│   └── references/
│       ├── motion-prompting.md
│       └── sora-api.md
├── b-roll/                     Step 4: B-roll (Kling 3)
│   ├── SKILL.md
│   └── references/
│       ├── kling-api.md
│       └── orchestrator.md
├── assemble/                   Step 5: Stitch, post, captions, or full-assemble
│   ├── SKILL.md
│   └── references/
│       ├── audio-orchestration.md
│       ├── green-zone.md
│       ├── orchestrator.md
│       ├── post-production.md
│       └── voice-system.md
├── score/                      Step 6: Virality scoring gate
│   ├── SKILL.md
│   └── references/
│       └── virality-scoring.md
├── scripts/                    10 automation scripts
├── evals/                      Baseline, trigger, and execution benchmarks
└── assets/                     Campaign brief template
```

## Brand & Campaign Context

ScrollClaw persists work across sessions so campaign 10 takes a fraction of campaign 1.

```
workspace/
├── brand/                      ← Read-only for ScrollClaw (GrowthClaw or manual)
│   ├── voice-profile.md        ← Informs script tone
│   ├── positioning.md          ← Informs persona research direction
│   └── audience.md             ← Anchors creator archetype selection
├── creators/                   ← Global creator profiles (reuse across campaigns)
└── campaigns/<slug>/
    ├── brief.md                ← Campaign brief
    ├── persona-research.md     ← Extracted customer language
    ├── creators/               ← Campaign-specific creator overrides
    ├── scripts/                ← Approved scripts
    ├── frames/                 ← First frames + context frames
    ├── clips/                  ← A-roll, B-roll, assembled finals
    ├── scores/                 ← Virality score cards
    ├── output-log.md           ← All prompt params (append-only)
    └── learnings.md            ← What worked, what didn't (append-only)
```

Full context protocol: [`_system/references/brand-campaign-context.md`](_system/references/brand-campaign-context.md)

---

Built by [Matt Berman](https://x.com/TheMattBerman) · [Emerald Digital](https://emeralddigital.dev) · [Big Players Newsletter](https://bigplayers.beehiiv.com)

Full documentation: [_system/SKILL.md](_system/SKILL.md)
