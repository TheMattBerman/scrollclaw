# Brand & Campaign Context Protocol

How ScrollClaw reads brand memory and persists campaign work across sessions.

---

## Why This Exists

Campaign 10 should take a fraction of campaign 1. Creator profiles get reused. Learnings compound. Brand voice carries across every script. This document defines how.

---

## Workspace Directory Structure

```
workspace/
├── brand/                          ← Read-only for ScrollClaw. Written by GrowthClaw or manually.
│   ├── voice-profile.md            ← Brand voice, tone, language style
│   ├── positioning.md              ← What the brand stands for, how it differentiates
│   └── audience.md                 ← ICP, customer archetypes, demographics
│
├── creators/                       ← Global creator profiles (reusable across campaigns)
│   └── creator-<name>.md
│
└── campaigns/
    └── <campaign-slug>/            ← One folder per campaign
        ├── brief.md                ← From assets/campaign-brief-template.md
        ├── persona-research.md     ← Written by /persona
        ├── creators/               ← Campaign-specific creator overrides (optional)
        │   └── creator-<name>.md
        ├── scripts/                ← Approved scripts
        │   └── <format>-script.md
        ├── frames/                 ← First frames + context frames
        │   ├── frame1.png
        │   └── environment-frame.png
        ├── clips/                  ← All video output
        │   ├── a-roll-01.mp4
        │   ├── b-roll-01.mp4
        │   └── final-<version>.mp4
        ├── scores/                 ← Virality score cards
        │   └── score-<version>.md
        ├── output-log.md           ← Prompt log, generation params, model versions
        └── learnings.md            ← What worked, what didn't (append-only — never overwrite)
```

---

## Brand Context Integration

ScrollClaw is a good citizen in a larger skill ecosystem. It **reads** from `workspace/brand/` but **never writes** there. Writing brand files is the job of brand-focused skills (GrowthClaw, brand-voice, etc.).

### What gets read and how

**`workspace/brand/voice-profile.md`**
→ Used by `/persona` to calibrate script tone and language style. If the brand voice is "conversational and direct, no corporate speak," scripts lean into informal sentence breaks, filler acknowledgments, real pauses.

**`workspace/brand/positioning.md`**
→ Used by `/persona` to frame what the product claims and how it differentiates. Shapes which pain points get emphasized in persona research.

**`workspace/brand/audience.md`**
→ Used by `/persona` to select creator archetypes. If the audience is "35-45 suburban moms," a 22-year-old creator profile is wrong. The audience file anchors creator selection.

### Graceful handling

Every skill that reads brand files must handle their absence gracefully. Do not error. Do not stall. Proceed standalone:

```
✓ Loaded brand voice: conversational-direct (workspace/brand/voice-profile.md)
✓ Loaded positioning (workspace/brand/positioning.md)
✗ No audience file found — proceeding standalone. Creator archetype will be inferred from campaign brief.
```

Show the user exactly what was loaded and what wasn't. Never silently skip.

---

## Context Matrix

Which sub-skills read and write which files.

| Skill | Reads | Writes |
|-------|-------|--------|
| `/persona` | `workspace/brand/voice-profile.md`<br>`workspace/brand/positioning.md`<br>`workspace/brand/audience.md`<br>`campaigns/<slug>/brief.md` | `campaigns/<slug>/persona-research.md`<br>`campaigns/<slug>/creators/creator-<name>.md`<br>`workspace/creators/creator-<name>.md` (global profiles)<br>`campaigns/<slug>/scripts/<format>-script.md` |
| `/first-frame` | `campaigns/<slug>/creators/creator-<name>.md`<br>`campaigns/<slug>/scripts/<format>-script.md`<br>`campaigns/<slug>/brief.md` | `campaigns/<slug>/frames/frame1.png`<br>`campaigns/<slug>/frames/environment-frame.png`<br>`campaigns/<slug>/output-log.md` |
| `/animate` | `campaigns/<slug>/frames/frame1.png`<br>`campaigns/<slug>/scripts/<format>-script.md`<br>`campaigns/<slug>/creators/creator-<name>.md` | `campaigns/<slug>/clips/a-roll-*.mp4`<br>`campaigns/<slug>/output-log.md` |
| `/b-roll` | `campaigns/<slug>/frames/environment-frame.png`<br>`campaigns/<slug>/clips/a-roll-*.mp4`<br>`campaigns/<slug>/scripts/<format>-script.md` | `campaigns/<slug>/clips/b-roll-*.mp4`<br>`campaigns/<slug>/output-log.md` |
| `/assemble` | `campaigns/<slug>/clips/*.mp4`<br>`campaigns/<slug>/scripts/<format>-script.md`<br>`campaigns/<slug>/creators/creator-<name>.md` | `campaigns/<slug>/clips/final-*.mp4`<br>`campaigns/<slug>/output-log.md` |
| `/score` | `campaigns/<slug>/clips/final-*.mp4`<br>`campaigns/<slug>/brief.md`<br>`campaigns/<slug>/persona-research.md` | `campaigns/<slug>/scores/score-<version>.md`<br>`campaigns/<slug>/learnings.md` (append-only) |

**What skills do NOT read:** `/animate` does not read brand files — brand context should already be baked into the script and creator profile by `/persona`. `/b-roll` does not read persona research — it needs the A-roll frames and script, nothing else. Keep dependencies narrow.

---

## Creator Profile Resolution Order

When a sub-skill needs a creator profile, it checks in this order:

1. `campaigns/<slug>/creators/creator-<name>.md` — campaign-specific override (takes priority)
2. `workspace/creators/creator-<name>.md` — global reusable profile

If neither exists, route back to `/persona` to create one.

**Creating a global vs campaign-specific profile:**
- Use `workspace/creators/` for creators that will appear across multiple campaigns (same creator in a 3-month run)
- Use `campaigns/<slug>/creators/` for one-off overrides (same creator archetype but different wardrobe for a specific campaign)

---

## Append-Only Files

`learnings.md` in each campaign folder is **append-only**. Never overwrite.

Format for each entry:

```markdown
## YYYY-MM-DD — [Campaign] [Format]

**What worked:**
- [specific finding]

**What didn't:**
- [specific finding]

**Threshold notes:** [did this video hit 70+? what dimension dragged it down?]
```

The `/score` skill appends to this file after every scored video. Over time, these learnings feed back into scoring thresholds and format selection.

---

## Output Log Format

`output-log.md` is a running log of all generation calls. Every skill appends to it. Never overwrite.

```markdown
## YYYY-MM-DD HH:MM — [Skill] [Step]

**Model:** [model name and version]
**Provider:** [fal / replicate / openrouter]
**Input:** [file or param]
**Output:** [file saved]
**Prompt hash or key params:** [brief summary — not the full prompt, just the key decisions]
**Generation time:** [seconds]
**Cost estimate:** [if known]
```

This log exists so future campaigns can audit what worked. If a video scores 85+, the output log tells you exactly what parameters produced it.

---

## Campaign Initialization

Before running any sub-skill, initialize the campaign workspace:

```bash
CAMPAIGN="ridge-q1"
mkdir -p workspace/campaigns/$CAMPAIGN/{creators,scripts,frames,clips,scores}
cp assets/campaign-brief-template.md workspace/campaigns/$CAMPAIGN/brief.md
touch workspace/campaigns/$CAMPAIGN/output-log.md
touch workspace/campaigns/$CAMPAIGN/learnings.md
```

Then fill in `brief.md` before running `/persona`.

---

## Cross-Campaign Learning

The `/score` skill appends learnings to `campaigns/<slug>/learnings.md`. For campaigns using the same creator or brand, these learnings inform:

- Which formats scored highest for this brand/audience combination
- Which hook types stopped the scroll
- Which creator archetypes outperformed

Before starting a new campaign for the same brand, read the learnings files from previous campaigns. Look for patterns. Don't repeat experiments that already failed.
