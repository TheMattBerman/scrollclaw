# Voice System

The voice makes or breaks realism. Perfect visuals, perfect lighting, perfect movement — none of it matters if the voice sounds robotic or has that text-to-speech quality. People scroll past immediately. They don't consciously register why. They just felt something was off.

## Tool: ElevenLabs

ElevenLabs V3 is the current best option for realistic AI voices. Easiest interface, most natural output.

### What NOT to use

**Do not use pre-made library voices.** They sound too generic and too polished. Everyone using ElevenLabs uses those same voices, which means your content sounds like everyone else's content. The viewer may not know why it sounds familiar, but their brain has heard that voice 50 times this week.

### Two approaches for custom voices

#### 1. Voice Design (generate from description)

Describe the voice you want and ElevenLabs generates a custom voice model.

**The critical instruction:** Include directions that make the voice sound like it's "in the actual room" — natural room tone, not studio-recorded. This is the single biggest difference between AI voice that works and AI voice that doesn't.

Example description:
```
Female, mid-20s, slightly raspy, casual speaking energy. 
Sounds like she's recording on her phone in her bedroom — 
not a studio, not a podcast mic. Slight room ambience. 
Natural pacing with occasional hesitation. 
American English, no strong regional accent.
Think "talking to a friend" not "recording a voiceover."
```

What to specify:
- Age and gender
- Vocal quality (raspy, clear, breathy, nasal, warm)
- Energy level (low-key, animated, deadpan, enthusiastic)
- Recording environment cue ("in a bedroom" not "in a studio")
- Speaking style ("talking to a friend" not "narrating")
- Accent/dialect if relevant

What to avoid specifying:
- "Professional voiceover quality"
- "Clear and articulate"
- "Broadcast quality"
- Anything that pushes toward polish

#### 2. Instant Voice Clone (from reference audio)

Find a video or audio clip of someone with the exact voice quality you want. Extract a 10-30 second clip of them speaking. Upload to ElevenLabs for analysis.

**Where to find reference voices:**
- TikTok/Reels creators with the right energy and vocal quality
- YouTube vlogs (not polished YouTubers — casual vloggers)
- Podcast guests (not hosts — hosts are too polished)
- Voice memos or casual interview clips

**Extraction tips:**
- 10-30 seconds of continuous speech
- Pick a segment where they're talking naturally, not performing
- Avoid segments with background music
- Some background noise is actually good — it trains the model to include room tone
- Multiple sentences, varied intonation — don't pick a monotone stretch

**What makes a good clone source:**
- Sounds like a real person talking (not presenting)
- Has natural imperfections (slight vocal fry, breathy moments, speed variation)
- Matches the energy of your creator profile
- Age and gender align with the visual creator

## Voice-to-creator matching

Each AI creator profile should have a matched voice. The voice personality section of the creator profile (speaking energy, verbal tics, opinion style) should align with the voice model characteristics.

Mismatches that break immersion:
- Young-looking creator with mature voice
- Energetic visual energy with flat vocal delivery
- Casual visual setting with polished broadcast voice
- American-looking creator with unexpected accent (unless intentional)

## Post-processing voice for realism

Even with a good voice model, raw TTS output is too clean. Apply these in post:

### Room tone
Layer ambient room sound under the voice. Match the environment shown in the video:
- Bedroom: quiet with occasional outside sounds
- Kitchen: fridge hum, slight echo
- Car: road noise, engine idle
- Coffee shop: ambient chatter, dishes

### Volume variation
Real phone recordings have uneven volume — the speaker moves closer and further from the mic. Add subtle volume automation (±2-3 dB, slow drift, not per-word).

### Compression artifacts
Phone mics compress audio aggressively. Apply light compression to simulate phone mic characteristics. Not heavy podcast compression — phone compression (less headroom, slightly crushed dynamics).

### Breath sounds
If the TTS doesn't include natural breath sounds between phrases, the lack of breathing is an uncanny valley trigger. Some TTS models handle this. If yours doesn't, consider adding subtle breath sounds at natural pause points.

### What NOT to do in post
- Don't add reverb (phone mics don't produce reverb — they produce room sound, which is different)
- Don't EQ for clarity (phone audio is not "clear" — it's slightly muffled and compressed)
- Don't normalize to consistent volume (real recordings aren't normalized)
- Don't remove background noise (the noise is what makes it real)

## Voice per format

| Format | Voice approach |
|--------|---------------|
| Talking Head Review | Direct voice, casual, matches creator's visual energy. Single clip = Sora built-in. Multi-clip = ElevenLabs S2S. |
| POV Product Demo | Optional voiceover via ElevenLabs TTS, or captions only (no voice). Hands-only format. |
| Wall of Text | No voice — text only |
| Visual Transformation Story | Voiceover narration via ElevenLabs TTS, slightly more structured but still human |
| Hybrid Transformation | Talking head bookends = S2S for consistency; slideshow section = TTS voiceover |
| Podcast Clip | ElevenLabs S2S always — Sora can't produce broadcast mic quality. Describe audio as "clean, natural, close and present" not by gear names. |

## Integration with the pipeline

### Script → Voice → Video assembly
1. Write script (from persona research, in creator's voice register)
2. Generate voice audio with matched voice model
3. Add room tone and post-processing
4. Generate video (first frame → Sora)
5. Sync audio to video in final assembly
6. Fine-tune timing — the voice should feel like it's driving the video, not laid on top

### Storing voice models
Track voice model IDs in the creator profile:
```markdown
## Voice Model
- ElevenLabs voice_id:
- Model version: v3
- Source: voice design / instant clone
- Clone source: [description or link if cloned]
- Room tone preset: [which ambient layer to use]
```
