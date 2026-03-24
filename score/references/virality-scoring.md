# Virality Scoring — Pre-Publish Quality Gate

Score every video before publishing. Only 70+ gets posted. This prevents wasting distribution on weak content.

## The 7 criteria

Score each 0-100, then average.

| Criterion | What it measures | What 90+ looks like | What <50 looks like |
|-----------|-----------------|--------------------|--------------------|
| **Hook strength** | Does the first 2s stop the scroll? | Emotive face + unexpected text combo | Generic opening, no pattern interrupt |
| **Emotional impact** | Does the viewer feel something? | Specific pain point that triggers recognition | Vague, could apply to anyone |
| **Pacing flow** | Does it hold attention throughout? | Each second earns the next, no dead spots | Slow middle, repetitive, viewer checks out |
| **Text readability** | Can text be read at scroll speed? | 3-5 words per line, in green zone, high contrast | Too small, too fast, blocked by UI |
| **Scroll-stop power** | Would this survive a fast scroll? | Visually distinct from surrounding content | Looks like every other video in the feed |
| **Completion likelihood** | Will viewers watch to the end? | Promise in hook is paid off, curiosity gap closed | Hook oversells, payoff is generic |
| **Shareability** | Would someone send this to a friend? | Contains a moment worth sharing — a take, a reveal, an emotion | Informational but not forward-worthy |

## Scoring prompt

Use a vision model (Gemini Flash, Claude) to score the final video. Extract 5 evenly-spaced frames if scoring from frames only.

```
Score this UGC video against 7 criteria, each 0-100.

Context:
- Platform: [TikTok / Instagram Reels / YouTube Shorts]
- Brand/niche: [brief description]
- Target audience: [who this is for]
- Duration: [Xs]
- Evaluation type: Frames only (no audio) / Full video with audio

Note: If evaluating frames only, mark audio-dependent scores (*) and note the limitation.

Criteria:
1. Hook strength* — does the first 2 seconds stop a fast scroll?
2. Emotional impact* — does the viewer feel a specific emotion?
3. Pacing flow — does every second earn the next?
4. Text readability — can all text be read at scroll speed, within platform safe zones?
5. Scroll-stop power — is this visually distinct from typical feed content?
6. Completion likelihood* — will a viewer watch to the end?
7. Shareability — would someone send this to a friend?

For each criterion:
- Score (0-100)
- One sentence explaining why

Hard gate: If Hook strength < 50, automatic NO-GO regardless of other scores.

Weighted score: (Hook × 0.20) + (Scroll-stop × 0.20) + (Completion × 0.20) + (Pacing × 0.15) + (Emotional × 0.15) + (Readability × 0.10) + (Shareability × 0.0)

Then:
- Weighted score
- GO/NO-GO (70+ weighted = GO, or Hook < 50 = auto NO-GO)
- The single highest-leverage fix: specific, implementable in <2 hours, with example copy or visual
- Estimated score if fix is applied
```

### Why weighted scoring (from testing)
The original equal-weighted prompt produced honest but flat scores. Testing revealed:
- Hook strength and scroll-stop power are 10x more important than shareability
- A bad hook should be a hard gate (auto NO-GO below 50) — nothing else matters if they scroll past
- Frames-only evaluation underscores audio-dependent criteria — mark those explicitly
- Platform context matters — "shareability" means different things on TikTok vs LinkedIn
- "Highest-leverage fix" must be specific and implementable, not vague ("add a hook")

## Thresholds

| Score | Action |
|-------|--------|
| 80+ | Publish immediately. This is strong. |
| 70-79 | Publish. Acceptable quality. |
| 60-69 | Fix the lowest-scoring criterion and re-score. |
| Below 60 | Regenerate. Don't polish a bad concept — start over. |

## Performance tracking (post-publish)

Track at 24h and 48h:

| Metric | Good | Great | Viral |
|--------|------|-------|-------|
| Views | 10K+ | 100K+ | 1M+ |
| Like ratio | 5%+ of views | 8%+ | 12%+ |
| Comment ratio | 0.5%+ of views | 1%+ | 2%+ |
| Share ratio | 0.2%+ of views | 0.5%+ | 1%+ |
| Watch-through rate | 40%+ | 60%+ | 80%+ |

## Winner replication

When a video hits "Great" or above:
1. Identify what worked — which emotion, which hook text pattern, which format
2. Generate 3-5 variations: same emotion + structure, different creator or angle
3. Test variations across platforms
4. Track which variation beats the original

**Do not repeat the exact same video.** Replicate the *pattern*, not the content. Same emotion, same structure, new script, new visual.

## Integration with the pipeline

Score BEFORE adding to any posting queue. The scoring step goes between post-production and distribution:

```
... → post-production → VIRALITY SCORE → publish (if 70+) → track → replicate winners
```

For batch campaigns, score all videos, rank by score, publish top performers first.
