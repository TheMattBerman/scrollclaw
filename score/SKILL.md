---
name: scrollclaw-score
description: "Score UGC videos for virality before publishing. 7 criteria, 0-100 each. Only 70+ gets published."
metadata:
  openclaw:
    emoji: "📊"
    user-invocable: true
    triggers:
      - "score video"
      - "virality score"
      - "ugc score"
      - "rate ugc"
      - "video quality check"
---

# Virality Scoring

Score every video before publishing. Read `references/virality-scoring.md` for the full methodology.

## Criteria

7 dimensions, scored 0-100 each:

1. **Hook Strength** — Does frame 1 + first 3 seconds force a pause?
2. **Emotional Impact** — Does it trigger a visceral response (not just "interesting")?
3. **Pacing** — Does every second earn the next second?
4. **Text Readability** — Are captions legible on mobile, properly timed?
5. **Scroll-Stop Power** — Would this stop a thumb mid-scroll in a feed?
6. **Completion Likelihood** — Will viewers watch to the end?
7. **Shareability** — Would someone send this to a friend?

## Thresholds

| Score | Action |
|-------|--------|
| 70+ | **Publish.** Ship it. |
| 60-69 | Polish — specific fixes can save it. Identify which dimensions are dragging. |
| Below 60 | **Regenerate.** Don't polish a bad clip. Go back to the failing stage. |

## Process

1. Watch the final video on a phone screen, in-app, scrolling past it like a user
2. Score each dimension independently
3. Calculate average
4. If below threshold, identify the weakest dimensions
5. Route back to the appropriate skill:
   - Hook/scroll-stop weak → `/first-frame` (regenerate canonical face)
   - Pacing/completion weak → `/persona` (restructure script)
   - Emotional impact weak → `/persona` (better language from research)
   - Text readability weak → `/assemble` (fix captions)
   - Audio/voice issues → `/assemble` (re-run S2S)

## Brand Memory Integration

### Reads
| File | Purpose |
|------|---------|
| `workspace/campaigns/<slug>/clips/final-*.mp4` | Video(s) to score |
| `workspace/campaigns/<slug>/brief.md` | Original campaign goals — score against intent, not just virality |
| `workspace/campaigns/<slug>/persona-research.md` | Whether the script language matches real customer language |

### Writes
| File | Notes |
|------|-------|
| `workspace/campaigns/<slug>/scores/score-<version>.md` | Score card with per-dimension breakdown and go/no-go |
| `workspace/campaigns/<slug>/learnings.md` | Append-only — what worked, what didn't, threshold notes |

### Context loading

```
📊 Score context loaded:
  ✓ Campaign: ridge-q1
  ✓ Final clips: 2 (workspace/campaigns/ridge-q1/clips/final-*.mp4)
  ✓ Brief: workspace/campaigns/ridge-q1/brief.md
  ✓ Persona research: workspace/campaigns/ridge-q1/persona-research.md
```

### Learnings append format

After every score, append to `workspace/campaigns/<slug>/learnings.md`:

```markdown
## YYYY-MM-DD — <campaign-slug> <format>

**Score:** <average>/100 (<go/no-go>)
**Dimension breakdown:** Hook <n> | Emotional <n> | Pacing <n> | Captions <n> | Scroll-stop <n> | Completion <n> | Share <n>

**What worked:**
- [specific finding]

**What didn't:**
- [specific finding]

**Remediation:** [if no-go: which skill to route back to and why]
```

Never overwrite this file. Only append.

## Output

- Virality score card in `workspace/campaigns/<slug>/scores/score-<version>.md`
- Go/no-go decision
- Learnings appended to `workspace/campaigns/<slug>/learnings.md`
- If no-go: specific remediation routing

## Batch Scoring

For campaign batches, score all variants and rank. Publish only the 70+ tier. Below-60 variants get regenerated, not tweaked.

```bash
bash scripts/batch-campaign.sh \
  --workspace campaigns/<slug> \
  --creators creators/ \
  --formats "talking-head,pov-demo,podcast-clip" \
  --dual-output
```
