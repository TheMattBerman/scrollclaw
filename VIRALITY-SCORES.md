# Virality Scoring Report — FitnessGM Test Campaign

**Date:** 2026-03-23  
**Scorer:** Claude Vision (claude-sonnet-4-6)  
**Method:** 5 evenly-spaced frames extracted per video via ffmpeg, scored against the 7-criteria system from `references/virality-scoring.md`  
**Videos tested:** 3

---

## Summary

| Video | Score | GO/NO-GO |
|-------|-------|----------|
| fitnessgm-full/final-with-voice.mp4 | 41/100 | ❌ NO-GO |
| fitnessgm-hookdemo/clips/hook-v10.mp4 | 51/100 | ❌ NO-GO |
| fitnessgm-podcast/clips/fal-podcast-12s.mp4 | 27/100 | ❌ NO-GO |

None of the three videos cleared the 70+ publish threshold. All three have the same root problem: **no strong visual hook in the first 2 seconds and no readable text overlays.**

---

## Video 1: final-with-voice.mp4

**Type:** Full podcast + B-roll edit (~47 seconds)  
**Frames extracted at:** 4s, 13s, 22s, 31s, 40s

### Scores

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Hook strength | 35 | Standard podcast shot with no visual surprise or bold caption to halt a fast scroll |
| Emotional impact | 45 | Host shows mild expressions, but no clear strong emotion or story moment |
| Pacing flow | 55 | One contrasting scene (cramped office) suggests some variation, but mostly repetitive talking-head shots |
| Text readability | 30 | Little-to-no large on-screen text; small background text (whiteboard) not legible at scroll speed |
| Scroll-stop power | 50 | Good production quality but aesthetically familiar (podcast setup), not visually unique |
| Completion likelihood | 40 | ~47s runtime with single-topic podcast format; unlikely to hold attention without compelling audio hook |
| Shareability | 35 | Informative but not emotionally striking or surprising |

**Overall Average: 41/100**  
**Verdict: ❌ NO-GO**

**Highest-leverage fix:** Add a bold, benefit-led visual + text hook in the first 1–2 seconds — a large readable caption (safe-zone friendly) that promises a clear payoff (e.g., "How to fix X in 30s" or a shocking stat) paired with an immediate cut to a visually surprising moment. This single change will dramatically increase scroll-stop, emotional curiosity, and completion.

---

## Video 2: hook-v10.mp4

**Type:** Hook face clip with captions (~4.3 seconds)  
**Frames extracted at:** 0.4s, 1.2s, 2.0s, 2.8s, 3.6s

### Scores

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Hook strength | 55 | Caption + close-up face are recognizable UGC hooks, but copy is slow and niche — only partly stops a scroll |
| Emotional impact | 50 | Creator's tired/frustrated expression is readable but low-intensity; unlikely to provoke strong feeling |
| Pacing flow | 45 | Almost no visual change or momentum over 4.3s; each second doesn't clearly earn the next |
| Text readability | 85 | Text is large, high-contrast, placed safely near the top — easy to read at scroll speed ✅ |
| Scroll-stop power | 40 | Reads like many other selfie-caption posts; not distinctive enough to stand out in feed |
| Completion likelihood | 50 | Short runtime helps, but lack of curiosity-building or a strong punch reduces casual-scroller completion |
| Shareability | 30 | Message is niche and mildly annoyed rather than entertaining or useful; unlikely to be forwarded |

**Overall Average: 51/100**  
**Verdict: ❌ NO-GO**

**Highest-leverage fix:** Make the first 1–2 seconds dramatically tighter and more visceral — replace the wordy caption with a 3–5 word high-impact hook (e.g., "Software losing members?"), add an immediate micro-action (fast cut to a visible error screen or a quick reaction zoom + punchy sound effect), and shorten copy so the viewer instantly understands the pain.

**Note:** Text readability (85) is this video's strongest element and the one thing working well. Build everything else around that strength.

---

## Video 3: fal-podcast-12s.mp4

**Type:** fal.ai-generated podcast clip (~12 seconds)  
**Frames extracted at:** 1s, 3.2s, 5.4s, 7.6s, 9.8s

### Scores

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Hook strength | 30 | Mid-shot of person with headphones/mic, nothing visually surprising, no bold headline |
| Emotional impact | 25 | Neutral-to-mildly-reactive facial expressions; little immediate emotional pull |
| Pacing flow | 40 | Small changes in hands/face suggest conversational variation, but no dynamic editing or strong beats |
| Text readability | 10 | No on-screen text visible in any frame; asset has no captions |
| Scroll-stop power | 30 | Standard podcast setup (headphones, mic, chair) with muted colors; indistinguishable from countless feed clips |
| Completion likelihood | 35 | Could hold attention at 12s if audio hook is strong, but visually nothing pushes viewers to watch through |
| Shareability | 20 | Nothing in imagery suggests a surprising, funny, or relatable moment worth forwarding |

**Overall Average: 27/100**  
**Verdict: ❌ NO-GO**

**Highest-leverage fix:** Add a bold, readable text hook overlay in the first 1–2 seconds (short, provocative one-liner in high-contrast colors inside safe zones) and pair it with a fast crop/zoom or jump-cut to the subject's strongest reaction. This is the single biggest missing element — without captions, this video is invisible to most viewers.

---

## Common Patterns Across All 3 Videos

1. **No captions on 2 of 3 videos.** Text readability scored 30, 85, 10. The hook demo is the only one with text — and it's the highest scorer overall.
2. **No visual pattern interrupt in the first 2 seconds.** All three open with a talking head or podcast setup. Nothing earns the scroll-stop.
3. **Podcast aesthetic is saturated.** The format is common enough that it needs significantly more production differentiation to stand out.
4. **The B-roll video (final-with-voice.mp4) has the best pacing** (55) but at 47 seconds is too long for weak hook entry.
5. **Shareability is universally low (20–35).** None of these contain a moment surprising or useful enough to forward.

---

## Scoring Prompt Evaluation

### Does the prompt work?

**Partially.** The 7-criteria system is well-chosen and produces scores that feel calibrated (the scores weren't inflated — all three videos failed, which matches the visual evidence). The structure is clean and the GO/NO-GO threshold at 70 is reasonable.

However, there are **5 significant problems** with the current prompt as written:

---

### Problem 1: "Watch this video" — but we're feeding frames

The prompt says *"Watch this UGC video"* but the tool receives static images. This creates a fundamental mismatch:

- **Hook strength** and **Completion likelihood** depend heavily on audio (voice, music, SFX) — frames can't evaluate these accurately
- **Pacing flow** depends on edit cuts visible in motion — 5 frames sample this poorly
- **Emotional impact** depends on tone of voice as much as facial expression

**Impact:** Scores for audio-dependent criteria are structurally underestimated. A video with a strong voiceover and weak visuals would score very low on this system even if it would actually perform well.

**Fix:** Add a required pre-scoring question: *"Does this evaluation include audio? If not, mark audio-dependent criteria (Hook strength, Emotional impact, Completion likelihood) with an asterisk and note the limitation."*

---

### Problem 2: No brand/audience context

The prompt gives no context about who the video is for or what platform it's designed for. This matters because:

- A 47-second video might be appropriate for YouTube Shorts (where it can perform) vs. TikTok (where it's risky)
- "Shareability" scoring depends heavily on knowing the target audience — niche B2B fitness software content is shared differently than consumer fitness
- "Scroll-stop power" standards differ between TikTok, Instagram Reels, and LinkedIn

**Fix:** Add context inputs at the top of the prompt:
```
Context:
- Platform: [TikTok / Instagram Reels / YouTube Shorts / LinkedIn]
- Brand: [brief description]
- Target audience: [who this is for]
- Video duration: [Xs]
```

---

### Problem 3: Criteria are unweighted but unequal in importance

All 7 criteria count equally toward the average. But for scroll-based short-form content:

- Hook strength and Scroll-stop power are **disproportionately important** — if you don't stop the scroll in 2s, none of the other criteria matter
- Shareability is **lower-stakes for most campaigns** (especially B2B)
- Text readability is **binary in practice** — either the text is readable or it isn't

A video could score 100 on Shareability and 20 on Hook strength and get a GO — which would be wrong.

**Fix:** Apply weights. Suggested distribution:
| Criterion | Weight |
|-----------|--------|
| Hook strength | 20% |
| Scroll-stop power | 20% |
| Completion likelihood | 20% |
| Pacing flow | 15% |
| Emotional impact | 15% |
| Text readability | 10% |
| Shareability | — (bonus, not included in GO/NO-GO score) |

Or simpler: make Hook strength a **hard gate** — if Hook strength < 50, automatic NO-GO regardless of other scores.

---

### Problem 4: The "highest-leverage fix" prompt is too open-ended

Asking for "the single highest-leverage fix" is good, but the responses tend to be generic ("add a hook") rather than specific ("replace frame 1 with a close-up of a frustrated face + caption 'Why gym software is losing you clients'").

**Fix:** Add specificity constraints:
```
The highest-leverage fix should be:
- Specific enough to implement in under 2 hours
- Reference a specific time code if possible (e.g., "change the opening 0-2s to...")
- Include example copy, visual, or edit suggestion
```

---

### Problem 5: The prompt is slightly too harsh for AI-generated content

These videos are AI-generated UGC, not studio productions. The scoring model is comparing them to polished native content. A 41/100 on final-with-voice.mp4 might be accurate vs. a TikTok gold standard, but relative to "AI-generated test content, how does this compare to other AI-generated content?" — it's a different question.

**Fix:** Add an optional calibration mode: `Scale: [Absolute (vs. top-performing content) / Relative (vs. AI-generated content averages)]`. Default to Absolute for final publish decisions, Relative for iteration feedback.

---

### Suggested Revised Prompt

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

---

## Prompt Verdict

**Current prompt:** Functional but underspecified. Produces honest scores (not inflated) but misses structural issues around audio, platform context, and criteria weighting.

**Recommended action:** Adopt the revised prompt above. The unweighted average and "Watch this video" instruction are the two highest-priority fixes.

---

*Report generated by: Virality Scoring Test (subagent)*  
*Frames saved to: ~/clawd/workspace/sora-ugc-test/virality-frames/*
