# Baseline vs ScrollClaw

Formal before/after evaluation to verify that ScrollClaw materially changes output quality versus a generic assistant.

---

## Eval 1 — Broad campaign request

**Prompt**

"Make me a UGC video for a dog food brand aimed at suburban dog moms."

### Baseline without ScrollClaw

- Produces a generic script fast
- Usually skips persona mining and exact customer language
- Tends toward polished ad phrasing
- No persistent creator profile or workspace structure
- No clear handoff from script to frame to video to scoring

### With ScrollClaw

- Starts at `/persona` and mines for exact language before writing
- Chooses a format intentionally instead of defaulting to a talking head monologue
- Creates reusable creator and campaign artifacts in `workspace/campaigns/<slug>/`
- Enforces `[A-ROLL]` and `[B-ROLL]` segmentation
- Routes through first frame, video generation, assembly, and scoring instead of stopping at copy

### Material difference

- Better messaging specificity
- Better system continuity
- Better downstream usability

---

## Eval 2 — Talking head script quality

**Prompt**

"Write a talking head review for my skincare serum."

### Baseline without ScrollClaw

- Uses testimonial cadence like "I've been using this for two weeks"
- Often writes one continuous monologue
- Weak or missing visual structure
- Sounds like marketing copy more than a person on a phone

### With ScrollClaw

- Pulls the format blueprint from the system context
- Requires Hook + Show + Verdict structure
- Forces a visual action in the show segment
- Rejects copywriter-sounding lines and rewrites toward conversational friction
- Requires approval before generation unless explicitly skipped

### Material difference

- Better taste transfer
- Better anti-slop defense
- Better readiness for video generation

---

## Eval 3 — Visual realism and assembly discipline

**Prompt**

"Finish this UGC video with B-roll, grain, and captions."

### Baseline without ScrollClaw

- Treats B-roll as generic filler
- May caption before post-production
- Does not insist on environment-matched start frames
- Often ignores voice continuity and clip normalization

### With ScrollClaw

- Uses environment matching for B-roll instead of generic stock visuals
- Makes captions explicitly last
- Separates `stitch`, `post`, and `captions` intents inside `assemble`
- Requires phone-test realism and stage-specific checkpoints before scoring

### Material difference

- Better continuity
- Better realism
- Lower chance of procedural mistakes that degrade the final asset

---

## Verdict

ScrollClaw justifies its context cost when the task is actual UGC production, not generic copy generation. The measurable improvements are:

- pipeline completeness instead of one-off deliverables
- stronger anti-AI realism defaults
- reusable campaign memory and creator persistence
- explicit failure handling between stages

If a task only needs one isolated artifact, baseline prompting may be enough. If the task needs a scroll-stopping UGC asset that can survive repeated use across campaigns, ScrollClaw materially changes the result.
