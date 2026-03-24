# Motion Prompting (Sora 2)

How to write Sora prompts that produce UGC-realistic video. Structured field format, not prose paragraphs.

## The structured format

Sora responds better to labeled sections than flowing descriptions. Each dimension gets its own field so the model knows what controls what.

```
Camera: [shot type, device, framing, movement]
Subject: [who, what they're doing, how they're doing it]
Dialogue: [exact words in quotes, delivery notes, lip sync note]
Audio: [room tone, background sounds, mic quality, music policy]
Environment & light: [setting, light sources, shadows, color feel]
Style & mood: [format reference, emotional register, realism level]
```

## Field-by-field guidance

### Camera
Lead with the device and shot type. Sora responds strongly to specific camera language.

**UGC camera language:**
- "handheld iPhone-style front camera" — the default for selfie UGC
- "phone propped on dashboard/counter/stack of books" — explains why the angle is slightly off
- "medium close-up from [surface] height" — anchors the framing
- "slight natural shake, fixed framing" — micro-movement without dramatic motion
- "POV looking down at hands" — for hands-only formats

**Never use for UGC:**
- dolly, steadicam, tracking shot, crane, slider
- shallow depth of field (phones have deep focus)
- any lens spec that implies a real camera (85mm, anamorphic)

### Subject
Describe the person generically. The first frame already defines their appearance — the motion prompt just needs to describe action and energy.

**Good:** "a man sits in a parked car at night, phone propped on the dashboard. He exhales, glances at the screen, then speaks slowly and honestly without looking polished or rehearsed."

**Bad:** "a 37-year-old male gym owner with dark brown hair, square jaw, stubble, wearing a charcoal polo..." — this level of detail triggers content filters and conflicts with the first frame.

**Key phrases that produce natural motion:**
- "speaks slowly and honestly"
- "without looking polished or rehearsed"
- "glances at the screen, then..."
- "exhales" (breathing makes motion natural)
- "shifts slightly in seat"
- "pauses mid-sentence"

### Dialogue
Include the actual script in quotes. Sora 2 generates synced audio from dialogue text.

**Delivery notes matter:**
- "lips synced, slightly uneven pacing" — prevents robotic delivery
- "quiet, almost to himself" — controls volume and energy
- "slight pause after '...'" — use ellipsis to create natural pauses
- "trails off at the end" — prevents clean TV-anchor endings

**Pacing tricks:**
- Ellipsis (...) creates pauses
- Em dash (—) creates restarts
- "like..." and "um" in the text create filler-word delivery
- Short sentences + long sentence + short sentence creates natural rhythm

### Audio
This is where most AI UGC fails. Describe the sound environment, not just the voice.

**Standard UGC audio block:**
```
Audio: quiet [environment] interior, [ambient sounds], 
subtle [physical sounds], no music, natural mic compression 
like a phone recording.
```

**Environment-specific:**
| Setting | Audio description |
|---------|------------------|
| Car | quiet car interior, faint city ambience outside, subtle seat movement, no music, natural mic compression like a phone recording |
| Bedroom | quiet room, faint outside traffic, occasional fabric rustle, no music, phone mic quality |
| Kitchen | slight room echo, distant appliance hum, occasional object contact, no music |
| Bathroom | slight tile reverb, exhaust fan hum, phone mic |
| Coffee shop | ambient chatter, dishes, espresso machine, no music |
| Podcast studio | clean, natural podcast audio. Voice is close and present with clear articulation and balanced warmth. Subtle room tone, not silent or dead. Sounds like a real conversational podcast recording, unprocessed and human. No background noise, no music. |

**Key insight from testing:** For podcast audio, describe the RESULT not the gear. "Clean, natural podcast audio, voice is close and present, subtle room tone, not silent or dead" works better than naming specific microphones (SM7B, Cloudlifter) or referencing specific podcasts. Sora responds to descriptions of how audio SOUNDS, not what equipment produced it.

### Environment & light
Describe the physical space and light sources. Be specific about what creates the light.

**Good:** "dark parked car, dashboard glow lighting his face from below, occasional passing streetlight flicker, soft shadows, muted colors"

**Bad:** "dramatic lighting, cinematic atmosphere" — this produces the exact opposite of UGC

**Key modifiers:**
- "muted colors" — prevents AI color saturation
- "soft shadows" — prevents dramatic contrast
- "occasional [light change]" — adds environmental motion
- Name real light sources: dashboard glow, streetlight, window, lamp, phone screen

### Style & mood
This is the overall vibe instruction. Reference the format type and emotional register.

**Strong style lines:**
- "raw UGC confessional" — tells Sora the genre
- "tired but relieved" — specific emotional state, not generic
- "intimate, unpolished realism" — anti-polish instruction
- "feels like a late-night personal video not meant for an audience" — the ultimate UGC frame

**Format references that work:**
- "raw UGC confessional"
- "casual phone diary entry"
- "voice memo to a friend"
- "impulse recording, not planned content"
- "the kind of video someone posts at midnight and deletes in the morning"

## Complete prompt template

```
Camera: handheld iPhone-style front camera, [shot type] from [surface] height, slight natural shake, fixed framing.
Subject: [person description — generic, action-focused, energy-focused]. [Key physical actions in sequence].
Dialogue: "[exact script with ellipsis for pauses and filler words for naturalness]" [delivery notes].
Audio: quiet [setting] interior, [2-3 ambient sounds], no music, natural mic compression like a phone recording.
Environment & light: [setting], [primary light source] lighting face from [direction], [secondary light], [shadow quality], muted colors.
Style & mood: raw UGC [sub-format], [emotional state], intimate, unpolished realism, feels like [analogy].
```

## Example: Coach Dan podcast clip (tested, audio works)

```
Camera: steady podcast camera, medium close-up, slightly off-center framing. No camera movement.
Subject: a man sits in a warm, modern podcast studio, speaking into a mounted microphone. He wears headphones, gestures naturally with one hand, occasionally glances off-camera, relaxed posture.
Dialogue: "So I'm sitting in my car right now. I know that sounds weird but like… this is the first time in three years I'm leaving at a normal hour. I used to be in that back office until ten, eleven at night. Not coaching. Not programming. Chasing people for money. And the fix was embarrassingly simple." spoken casually, thinking out loud.
Audio: clean, natural podcast audio. Voice is close and present with clear articulation and balanced warmth. Subtle room tone, not silent or dead. Sounds like a real conversational podcast recording, unprocessed and human. No background noise, no music.
Environment: cozy podcast studio with wood slat walls, warm amber lighting, soft shadows, plants in the background. Depth and texture visible, not sterile.
Style: candid, real podcast clip. Intimate, slightly tired tone. Not performative.
```

## Example: Coach Dan car confession

```
Camera: handheld iPhone-style front camera, medium close-up from dashboard height, slight natural shake, fixed framing.
Subject: a man sits in a parked car at night, phone propped on the dashboard. He exhales, glances at the screen, then speaks slowly and honestly without looking polished or rehearsed.
Dialogue: "so I'm sitting in my car right now… and I know that sounds weird but like… this is the first time in three years I'm leaving at a normal hour. I used to be in that back office until ten, eleven at night. not coaching. not programming. chasing people for money." lips synced, slightly uneven pacing.
Audio: quiet car interior, faint city ambience outside, subtle seat movement, no music, natural mic compression like a phone recording.
Environment & light: dark parked car, dashboard glow lighting his face from below, occasional passing streetlight flicker, soft shadows, muted colors.
Style & mood: raw UGC confessional, tired but relieved, intimate, unpolished realism, feels like a late-night personal video not meant for an audience.
```

## What NOT to include in motion prompts

- Detailed physical descriptions of the person (first frame handles this)
- Camera equipment specs beyond "iPhone-style"
- Color grading instructions (first frame + post-production handle this)
- Multiple camera angles in one clip
- Complex choreography or multiple actions
- Background music requests
