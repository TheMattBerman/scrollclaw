---
name: scrollclaw-persona
description: "Start of the UGC pipeline for persona research, creator profiles, format selection, and scriptwriting. Use when the user is clearly asking for messaging work rather than broad full-pipeline orchestration."
metadata:
  openclaw:
    emoji: "🎭"
    user-invocable: true
    triggers:
      - "persona research"
      - "ugc persona"
      - "ugc script"
      - "ugc research"
      - "write ugc script"
      - "creator profile"
      - "format selection"
      - "script rewrite"
---

# Persona & Script

Everything starts here. No first frames, no animation, no audio until the messaging is locked.

## Step 1: Persona Research (do not skip)

Read `references/persona-research.md`. Minimum 60 minutes mining competitor reviews on Amazon, Trustpilot, Reddit. Copy exact phrases — do not paraphrase.

You're looking for exact language, not information:
- "I was doing everything right and my body wasn't cooperating" → goes into a script
- "I finally feel like myself again" → useless, discard
- "I wore a dress I hadn't put on since my daughter was born and cried in the fitting room" → this is what you want

Specific language produces viewers who can viscerally imagine the result. Generic language produces viewers who merely understand it's possible. The first converts. The second doesn't.

## Step 2: Brand Context

Load brand voice file if it exists. Know the product, the audience, the vibe.

## Step 3: Creator Profiles

Each creator gets a profile in `workspace/campaigns/<slug>/creators/creator-<name>.md` for campaign-specific work, or `workspace/creators/creator-<name>.md` for reusable global profiles. Read `references/script-voice.md` for voice calibration.

```bash
bash scripts/create-creator.sh <workspace> <creator-name>
```

## Step 4: Format Selection

Refer to the format table in the system context (loaded automatically). Ask the user what they're making and guide them.

**For Hook Face + Demo:** always recommend real demo footage (screen recording) over AI-generated demo. The hook face stops the scroll — the demo should be the real product. Use `scripts/build-hook-demo.sh` to combine.

## Step 5: Script

Read `references/script-voice.md`. Use exact phrases from persona research. Test every line: if it sounds like a copywriter wrote it, rewrite until it sounds like someone talking to their phone.

**FORMAT ENFORCEMENT (mandatory):** Before writing, pull the shot breakdown from `the format table in the system context (loaded automatically)` for the chosen format. The script MUST map to the shot breakdown:

| Format | Script must have |
|--------|-----------------|
| Talking Head | Hook (0-4s) + Show (4-12s) + Verdict (12-20s). SHOW must include a visual action. |
| Hook Face + Demo | Hook face with emotion + text (0-4s) + hard cut + Demo (4-14s). Hook has NO dialogue. |
| Podcast Clip | Mid-conversation entry + The take + The beat. Must reference unseen host. |
| Visual Transformation | Hook frame with concept name + Before + Turning point + After + Close |
| Hybrid Transformation | Talking head before + Slideshow mechanism bridge + Talking head after |
| Wall of Text | Dense text only — no voice, no video gen |

**Validation:** After writing, map each line to a segment. If any segment is missing or the script is one continuous monologue with no visual structure — rewrite. A script without visual beats is not a script, it's a ramble.

**Present the script to the user for approval** before generating anything. Include the segment mapping. User can override with "skip approval" for autonomous generation.

Mark the script with `[A-ROLL]` and `[B-ROLL]` tags. A-roll = Sora (talking head + dialogue). B-roll = Kling (everything else). Voice runs continuously over B-roll.

## Brand Memory Integration

### Reads
| File | Purpose |
|------|---------|
| `workspace/brand/voice-profile.md` | Script tone calibration — if brand voice is "conversational-direct," lean into informal breaks and real pauses |
| `workspace/brand/positioning.md` | Which pain points to emphasize; how the product differentiates |
| `workspace/brand/audience.md` | Creator archetype selection — anchors age, lifestyle, aesthetic |
| `workspace/campaigns/<slug>/brief.md` | Campaign-specific product, goal, and format direction |

### Writes
| File | Notes |
|------|-------|
| `workspace/campaigns/<slug>/persona-research.md` | Extracted phrases, pain points, exact customer language |
| `workspace/campaigns/<slug>/creators/creator-<name>.md` | Campaign-specific creator profile |
| `workspace/creators/creator-<name>.md` | Global reusable profile (when creator will appear across campaigns) |
| `workspace/campaigns/<slug>/scripts/<format>-script.md` | Approved script with A/B-roll tags |

### Context loading (show this to the user at session start)

```
📋 Context loaded for campaign: <slug>
  ✓ Brand voice: <tone from voice-profile.md> (workspace/brand/voice-profile.md)
  ✓ Positioning: <one-line summary> (workspace/brand/positioning.md)
  ✗ No audience file found — creator archetype will be inferred from campaign brief
  ✓ Campaign brief: workspace/campaigns/<slug>/brief.md
```

Handle missing files gracefully. Never error. Proceed standalone with a note.

## Contract

### Input
- Required: campaign brief plus a clear product, audience, or offer to write from
- Optional: `workspace/brand/{voice-profile,positioning,audience}.md`, existing creator profiles, format preference
- Format: brief, raw brand notes, review mining inputs, and workspace markdown files
- Source: user prompt, `workspace/campaigns/<slug>/brief.md`, and upstream brand memory files

### Output
- Produces: persona research, creator profile(s), and one approved script with `[A-ROLL]` and `[B-ROLL]` tags
- Format: markdown files in `workspace/campaigns/<slug>/` plus inline script review for approval
- Default behavior: do the research, choose the format, and present the script for approval before any visual generation
- Downstream use: `/first-frame`, `/animate`, `/b-roll`, `/assemble`, `/score`

### Validation
- Pre-conditions: campaign brief exists and there is enough product context to identify a real customer problem
- Post-conditions: script maps to the format blueprint, uses exact customer language, and has explicit visual beats
- Failure checks: do not advance with generic copy, missing segment mapping, or an unapproved script unless the user explicitly says to skip approval

## Output

- Persona research doc with extracted phrases — `workspace/campaigns/<slug>/persona-research.md`
- Creator profile(s) in `workspace/campaigns/<slug>/creators/` (or `workspace/creators/` for global)
- Approved script with segment mapping and A/B-roll tags — `workspace/campaigns/<slug>/scripts/<format>-script.md`
- Format selection locked

## Next Step

Script approved → run `/first-frame` to generate the canonical face image.
