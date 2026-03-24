# Audio Orchestration

One voice, one pass, continuous throughout. B-roll swaps visuals only — audio never cuts.

## The problem

Each Sora clip generates its own voice. Different timbre, pacing, and tone across clips. Stitching them sounds like three different people. This is the #1 production issue with multi-clip UGC.

## The solution: S2S (Speech-to-Speech)

Do NOT use text-to-speech — it won't match lip sync timing. Use ElevenLabs speech-to-speech: transform the voice character while preserving the original timing and pacing.

### Pipeline

```
Step 1: Stitch A-roll video clips only (no B-roll) → continuous video+audio base
Step 2: Extract audio from stitched A-roll → this is the timing reference
Step 3: ElevenLabs S2S → transforms voice, keeps timing → one consistent voice
Step 4: Lay S2S voice back onto A-roll video (replacing original audio)
Step 5: Segment the video — cut at B-roll insertion points
Step 6: Insert B-roll clips (video only, no audio) at the right timestamps
Step 7: Concatenate all segments → final video
Step 8: Lay S2S voice onto the final video track → done
```

### Why this order matters

The A-roll drives the timeline. B-roll is visual-only overlay. If you stitch all clips (A+B) first then try to sync audio, the timing breaks because B-roll adds visual duration that doesn't exist in the voice track.

### ElevenLabs S2S endpoint

```bash
# Create a custom voice first (voice design)
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-voice/create-previews" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "voice_description": "Male, mid-30s, casual, slightly raspy...",
    "text": "sample text for preview"
  }'
# Returns: { "previews": [{ "generated_voice_id": "..." }] }

# Save the voice
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-voice/create-voice-from-preview" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"voice_name": "Coach Dan", "generated_voice_id": "...", "voice_description": "..."}'
# Returns: { "voice_id": "..." }

# Speech-to-speech transform
curl -s -X POST "https://api.elevenlabs.io/v1/speech-to-speech/{voice_id}" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -F "audio=@voice-concat.wav" \
  -F "model_id=eleven_english_sts_v2" \
  --output voice-s2s.mp3
```

### Key details (from real testing)
- S2S preserves timing within ~0.01 seconds — lip sync still matches
- Voice design description should match the creator profile's voice personality
- The S2S model is `eleven_english_sts_v2`
- Input: WAV or MP3. Output: MP3.
- Store the voice_id in the creator profile for reuse across campaigns

## Video assembly with FFmpeg

### Step 1: Stitch A-roll only
```bash
# Concat A-roll clips (all 720x1280, 30fps)
ffmpeg -f concat -safe 0 -i aroll-list.txt -c copy aroll-stitched.mp4
```

### Step 2: Replace audio with S2S voice
```bash
ffmpeg -i aroll-stitched.mp4 -i voice-s2s.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k \
  -shortest aroll-with-voice.mp4
```

### Step 3: Segment and insert B-roll
Cut the A-roll video at B-roll insertion points, splice B-roll in:
```bash
# Extract A-roll segments (video only)
ffmpeg -i aroll-with-voice.mp4 -ss 0 -t 8 -an seg1-aroll.mp4
ffmpeg -i broll-office-720.mp4 -t 5 -an seg2-broll.mp4
ffmpeg -i broll-phone-720.mp4 -t 4 -an seg3-broll.mp4
ffmpeg -i aroll-with-voice.mp4 -ss 17 -t 5 -an seg4-aroll.mp4
ffmpeg -i broll-walkout-720.mp4 -t 5 -an seg5-broll.mp4
ffmpeg -i aroll-with-voice.mp4 -ss 27 -an seg6-aroll.mp4

# Concat all segments
ffmpeg -f concat -safe 0 -i segments.txt -c copy video-only.mp4

# Lay voice on final video
ffmpeg -i video-only.mp4 -i voice-s2s.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -shortest final.mp4
```

### B-roll insertion timing

B-roll should cut in at moments that match the script content:
- Visual matches words: "entering credit card numbers" → show the back office
- Visual builds emotion: phone notifications stacking during a pause
- Visual foreshadows: walking out of gym just before the payoff line

Don't insert B-roll at random — the visual-verbal alignment is what makes it feel produced, not assembled.

## Resolution normalization

**All clips must be the same resolution before concatenation.** Sora outputs 720x1280, Kling outputs 1076x1924 or 1080x1920. Mixed resolutions cause display issues.

```bash
# Force all clips to 720x1280
ffmpeg -i input.mp4 \
  -vf "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:black" \
  -r 30 -c:v libx264 -preset fast -crf 18 \
  -c:a aac -b:a 128k -ar 44100 \
  output-720.mp4
```

Use the `stitch-video.sh` script which handles this automatically.

## Audio rules per format (TESTED — follow exactly)

**CRITICAL: Sora's native voice is ALWAYS better than ElevenLabs TTS for talking head content.** TTS sounds overproduced and fake. Sora generates voice + lip sync together — that sync is the whole point. Only use ElevenLabs S2S (speech-to-speech) when you must unify voices across multiple Sora clips.

**NEVER use ElevenLabs TTS (text-to-speech) for talking head or dialogue content.** TTS produces a voice that sounds like a voice assistant, not a person. S2S transforms an existing voice while keeping timing — that's different and acceptable.

| Format | Audio approach |
|--------|---------------|
| Talking Head (single clip) | **Sora built-in only.** Native voice + lip sync. Do not replace. |
| Talking Head (multi-clip) | Sora built-in per clip → stitch → S2S to unify voices. Never TTS. |
| Hook Face + Demo | Sora generates voice in the face clip. B-roll gets ambient only. Sora voice continues over B-roll cutaways. |
| Podcast (single clip) | **Sora built-in.** Describe audio as "clean, natural, close and present." |
| Podcast (multi-clip) | Sora built-in per clip → stitch A-roll → S2S to unify → insert B-roll visual-only |
| POV Demo | Voiceover via ElevenLabs TTS acceptable here (no face, no lip sync needed). Or captions only. |
| Wall of Text | No voice — text only |
| Visual Transformation | ElevenLabs TTS for voiceover narration (no face, no lip sync) |
| Hybrid Transformation | Talking head bookends: Sora built-in → S2S if multi-clip. Slideshow: TTS voiceover OK. |

**When ElevenLabs S2S is needed (multi-clip stitching):**
- Use voice CLONE from a reference audio that sounds real, not voice DESIGN (which sounds overproduced)
- S2S transforms the voice character while preserving Sora's natural timing and pacing
- The lip sync still works because timing is preserved

**When ElevenLabs TTS is acceptable:**
- ONLY for voiceover narration where there is no face on screen (POV Demo, Visual Transformation slideshow sections)
- Never for content where a face is visible and should be "speaking"
