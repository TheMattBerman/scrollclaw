# UGC Format Library

Six formats. Each exists because it produces a distinct behavior shift that the others can't. No filler.

Pick the format, adapt the shots to your product, fill in the script.

---

## 1. Talking Head Review

The workhorse. One person, one camera, honest opinion. This is where most campaigns should start.

**When to use:** product reviews, software reactions, honest takes, "I tried this" content, car confessions
**Duration:** 15-25 seconds (2-3 Sora segments)
**Camera:** front-facing selfie angle, slightly off-center, stationary with micro-shake

### Shot breakdown
| Segment | Seconds | What happens | Camera | Energy |
|---------|---------|-------------|--------|--------|
| Hook | 0-4 | Creator states the thing they tried or discovered. Direct to camera. Mid-sentence start. | Selfie angle, eye-level, phone propped | Casual, slightly skeptical |
| Show | 4-12 | Holds product up, shows result, or demonstrates. May look down at product then back to camera. | Same angle, creator moves product into frame | Building interest |
| Verdict | 12-20 | Honest reaction. Not polished — hedging, surprise, mild annoyance that it works. | Same angle | Genuine, unscripted feel |
| CTA | 20-25 | "Link in bio" or "comment if you want the link" — throwaway, not produced | Same angle | Low-key |

### Environment: bedroom, bathroom counter, car (parked), kitchen table
### Lighting: natural window light or overhead room light. No ring light glow.

---

## 2. Hook Face + Demo

Emotive face stops the scroll, then hard cut to product demo. The proven 15-second UGC formula from high-volume operators.

**When to use:** app demos, tool walkthroughs, any product that needs showing not telling
**Duration:** 15 seconds MAX (hard limit — completion rate drops hard after 15s)
**Camera:** face hook is selfie/front-facing, demo is POV hands or screen recording

### Shot breakdown
| Segment | Seconds | What happens | Camera | Energy |
|---------|---------|-------------|--------|--------|
| Hook face | 0-3 | Creator's face with a strong emotion (shocked, frustrated, confused). Text overlay with hook line. Minimal movement — a blink, slight head shake, eyes widening. Face doesn't talk. | Selfie angle, steady | Emotional, pattern interrupt |
| Hard cut | 3 | Instant transition. No fade, no transition effect. | — | — |
| Demo | 3-13 | Product in action. Hands on phone/laptop, screen recording, app walkthrough. Real screenshots composited onto devices. | POV looking down at hands/screen, slight handheld | Focused, showing not telling |
| Result/CTA | 13-15 | The outcome visible. Clean screen showing the result. Or cut back to face with relieved/happy expression. | Same or back to face | Satisfied, understated |

### The hook face
Read `references/hook-emotions.md` for the full emotion taxonomy and Nano Banana prompt templates. The face is generated with Sora i2v — one expression, minimal animation, no dialogue. The text overlay carries the message.

### The demo section
- **App/SaaS:** real app screenshots or screen recordings composited onto phone/laptop. AI cannot generate readable UI.
- **Physical product:** Kling i2v with product as start image. Hands interacting naturally.
- **Best as Kling B-roll** — hands + product is where Kling excels. No face consistency issues.

### Text overlay
- Hook text on the face (3-7 words per line, max 3 lines)
- Green zone positioning — see `references/green-zone.md`
- Use hook text templates from `references/green-zone.md`
- Platform-native font (TikTok Sans for TikTok, Helvetica for IG)

### Why 15 seconds
Completion rate data from high-volume UGC campaigns: 15s is the ceiling for cold traffic. Beyond 15s, watch-through drops below the threshold where platforms distribute the content. Every second must earn the next second.

---

## 3. Wall of Text

Person on screen with subtle movement, overwhelmed by dense text that fills the upper portion. Creates a curiosity trap — viewer can't read it all in the first few seconds so they stop scrolling to finish.

**When to use:** hot takes, lists, confessions, "things nobody tells you," relatable rants, controversial opinions
**Duration:** 4-8 seconds
**Camera:** close-up or medium of a person with subtle movement (hair touch, blink, slight sway, knowing look)

### Production
1. Generate face/scene with Nano Banana (person with a relevant expression — knowing smirk, eye roll, relatable "yep" energy)
2. Animate with Sora i2v (4-8s, SUBTLE movement only — not talking, not dramatic. A blink, hair touch, slight head tilt. The person is the backdrop, the text is the content.)
3. Burn dense text overlay on top (NO pill background — just white text with drop shadow)

### Text style (critical — must match TikTok native)
- **No background pills.** Just bold white text with a subtle black drop shadow.
- **All lowercase** — feels typed, not designed. Occasional CAPS for emphasis on key words only.
- **Centered text, filling the upper 40-60% of the frame**
- **Dense** — way more text than can be comfortably read in the clip duration. That's the point.
- **Conversational stream of consciousness** — reads like someone typed it in one sitting
- **Font:** TikTok Sans or similar bold sans-serif. NOT the pill caption system — this is a different style entirely.

### Example text style
```
my favorite hobby is paying off
my credit card. i pay my credit
card bill AT LEAST once a
week. you will NOT catch me in
credit card debt. slow at work?
might as well pay off my credit
card. day off? guess i'll pay my
credit card. bad date? i'll be
sneaking to the bathroom to
pay my credit card.
i love paying my credit card.
```

### Why it works
The cognitive load mismatch (too much text, too little time) triggers the completion impulse. The viewer's brain started reading and now needs to finish. This beats the scroll reflex by hijacking a different cognitive drive entirely. The person on screen with subtle movement makes it feel like a real post, not a graphic.

---

## 4. Visual Transformation Story

Faceless. All generated imagery. Strong named hook. Static images animated through Sora and stitched together to tell a visual story.

This format has two speeds:

**Quick B/A (10-15s):** simple before/after — same angle, same lighting, show the change. "Before" state, brief process, "after" reveal. Works for any visible transformation.

**Full narrative (15-25s):** named concept hook ("the divorce effect"), 3-5 image segments animated with subtle motion, text overlays or voiceover. The name IS the scroll-stopper.

**When to use:** visual transformations, brand origin stories, dramatic before/after arcs, any story where showing beats telling
**Duration:** 10-25 seconds depending on speed
**Camera:** varies per segment — each image is a distinct scene animated into subtle motion

### Shot breakdown (full narrative)
| Segment | Seconds | What happens | Camera | Energy |
|---------|---------|-------------|--------|--------|
| Hook frame | 0-4 | The concept name. Bold text over an emotionally charged image. "The divorce effect." "The 5AM shift." | Slow push-in or parallax | Tension, curiosity |
| Before state | 4-10 | 1-2 images showing the "before." Real, raw, unglamorous. Same character. | Slow drift or subtle movement | Heavy, honest |
| Turning point | 10-14 | The moment of change. Single powerful image. | Hold or slow reveal | Pivotal |
| After state | 14-20 | 1-2 images showing the "after." Same person, different energy. | Gentle movement, more alive | Lighter, resolved |
| Close | 20-25 | Final frame — the concept name again or a one-line takeaway. | Static or very slow zoom out | Definitive |

### Shot breakdown (quick B/A)
| Segment | Seconds | What happens | Camera | Energy |
|---------|---------|-------------|--------|--------|
| Before | 0-4 | Show the "before" state. Same angle as after. | Locked angle, consistent lighting | Neutral |
| Process | 4-8 | Quick montage or time-lapse feel. | Same angle or POV hands | Active |
| After | 8-15 | Reveal. Same angle as before. Let the difference speak. | Same angle as before shot | Satisfied, understated |

**Critical for quick B/A:** same lighting, same angle, same framing for before and after. The visual match is what sells it.

### The hook name matters (full narrative)
"The divorce effect" is scroll-stopping. "How divorce changed me" is not. The concept needs a NAME — something that sounds like a phenomenon, not a diary entry.

### Production pipeline
1. Name the transformation (for full narrative — the name IS the hook)
2. Generate images with Nano Banana (lock character identity across all)
3. Animate each with Sora i2v (4-5 seconds each, subtle motion only)
4. Stitch segments (ffmpeg concat)
5. Add text overlays and/or voiceover in post
6. Color grade for consistency across all segments

### Character consistency
Same person in every frame. Same face, same distinguishing features, different wardrobe/setting as the story progresses. Same Nano Banana reference and Sora character_id throughout.

---

## 5. Hybrid Transformation (Talking Head + Slideshow)

The format that crossed $100k. Talking-head bookends with a voiceover slideshow mechanism bridge in the middle. The talking head creates identification. The slideshow maintains attention through the mechanism section (where pure talking-head retention drops). The talking-head close delivers the transformation moment with eye contact.

**When to use:** products with complex mechanisms, health/wellness/fitness transformations, anything where the "why it works" section is necessary for conversion
**Duration:** 20-30 seconds (3 segments: talking head + slideshow + talking head)
**Camera:** selfie for bookends, generated imagery for slideshow

### Shot breakdown
| Segment | Seconds | What happens | Camera | Energy |
|---------|---------|-------------|--------|--------|
| Talking head — before state | 0-6 | Creator in their "before" context. Uses exact language from persona research. States the problem with personal specificity. | Selfie, slightly tired/frustrated energy, real environment | Heavy, honest, identification |
| Slideshow — mechanism bridge | 6-18 | AI voiceover narrates how/why the product works over contextual images. Images align with each voiceover moment — not generic product shots. | Generated images animated with subtle Sora motion (slow zoom, parallax, gentle drift) | Explanatory, building, visual variety |
| Talking head — after state | 18-25+ | Creator in their "after" context. The specific transformation moment — not "it worked" but the exact scene where they knew. | Same selfie setup, visibly different energy | Resolved, genuine, specific |

### Why the slideshow section works
Pure talking-head content loses retention during the mechanism bridge. The slideshow provides visual variety that maintains attention. Each image matches what the voiceover is saying at that exact moment.

### Image-audio alignment rules
- Voiceover describes the problem → images show contextual scenes of the problem
- Voiceover explains the mechanism → images visualize the concept
- Voiceover introduces the product → product in real-world context
- Never generic product-on-white

### Production pipeline
1. Persona research first (see `persona-research.md`) — minimum 60 minutes
2. Script with exact phrases from reviews
3. Generate creator "before" state → Sora i2v (bookend 1)
4. Generate 4-6 contextual images for slideshow (matched to voiceover moments)
5. Animate slideshow images → Sora i2v (3-4 seconds each)
6. Generate creator "after" state → Sora i2v (bookend 2)
7. Generate voiceover (add room tone and background noise)
8. Stitch all segments, full post-production pass

### When to pick this over Visual Transformation Story
- Visual Transformation Story: transformation is primarily visual, hook name carries it
- Hybrid: mechanism matters for conversion, persona depth available, "why it works" is the sell

---

## 6. Podcast Clip

Fake podcast clip. Creator as "guest" — Shure mic, over-ear headphones, warm lighting, cozy studio backdrop. Mid-conversation with unseen host.

Borrows authority from the podcast context. Viewers perceive podcast guests as credible experts, not advertisers. The mic + headphones + warm lighting signals "invited to speak" not "selling something."

**When to use:** expert positioning, credibility plays, product recommendations needing authority, founder stories, industry takes
**Duration:** 8-20 seconds (1-2 Sora segments)
**Camera:** medium close-up, slightly off-center, steady (NOT handheld — podcasts use tripods)

### The podcast set
- **Mic:** professional condenser on boom arm (Shure SM7B aesthetic)
- **Headphones:** over-ear studio headphones (must be visible — strongest signifier)
- **Lighting:** warm ambient glow behind/beside creator. LED through wood slats, table lamp. NOT fluorescent, NOT ring light
- **Backdrop:** wood slat panel, plants, bookshelf, fabric couch. NOT blank wall, NOT corporate
- **Seating:** couch, armchair, or high stool. Relaxed posture.
- **Vibe:** warm amber, cream/beige couch, casual clothing. "Intimate studio conversation."

### Shot breakdown
| Segment | Seconds | What happens | Camera | Energy |
|---------|---------|-------------|--------|--------|
| Mid-conversation entry | 0-3 | Creator already talking — drop in mid-thought. No intro. | Medium close-up, steady, off-center | Engaged, thoughtful |
| The take | 3-15 | Main insight or recommendation. Authority of being interviewed, not selling. Eye contact with unseen host (slightly off-camera). | Same framing, may lean forward | Direct, genuine authority |
| The beat | 15-20 | Natural pause, knowing look, slight nod — the save-worthy moment. | Same framing | Punctuation |

### Script approach
- Reference unseen host: "yeah exactly," "no that's a good question"
- Mid-sentence entries — ongoing conversation
- Explaining to interested peer, not pitching to customer
- No CTA — the podcast doesn't sell. Caption/bio does.

### Production notes
- Camera is steady (not handheld). Creator shifts, camera doesn't.
- **Audio (tested):** describe the result, not the gear. What works: "Clean, natural podcast audio. Voice is close and present with clear articulation and balanced warmth. Subtle room tone, not silent or dead. Sounds like a real conversational podcast recording, unprocessed and human. No background noise, no music." What doesn't work: naming specific mics (SM7B), referencing specific podcasts, or ASMR framing. Sora responds to how audio sounds, not what equipment produced it.
- Color grade warmer — amber/warm tones correct here (real podcast studios have warm lighting).

---

## Format selection guide

| If the goal is... | Use this format |
|-------------------|-----------------|
| Product review / honest take / confession | Talking Head Review |
| App / tool / hands-on demo (faceless) | POV Product Demo |
| Hot take / data dump / controversial (faceless) | Wall of Text |
| Visual before/after / named transformation | Visual Transformation Story |
| Complex mechanism + deep persona | Hybrid Transformation |
| Expert authority / credibility play | Podcast Clip |

## Combining formats

These are composable. Strong combinations:
- **Talking Head + POV Demo** — face for hook/verdict, hands for the show section
- **Podcast Clip + B-roll** — podcast A-roll with Kling product B-roll intercut
- **Wall of Text → Talking Head** — text hook catches attention, cuts to creator explaining
- **Hybrid Transformation** already combines talking head + slideshow by design

The shot breakdowns prevent two failures: formless rambling and over-produced structure. Stay between those.
