# Post-Production Realism

Raw AI output looks like AI output. Post-production is where "generated" becomes "could be real." Skip this step and nothing else matters.

## The realism stack

Apply these in order. Each layer compounds.

### 1. Color grade for realism

AI video comes out too clean, too contrasty, too saturated. Real phone footage doesn't look like that.

**Do this:**
- Drop contrast 10-15%
- Push shadows up (lift the blacks — phone cameras don't produce true black)
- Add slight fade to highlights
- Desaturate 5-10% (phone cameras oversaturate but not in the AI way)
- Slight warmth shift if indoor lighting (phone auto-white-balance leans warm)

**Don't do this:**
- Cinematic color grading (teal and orange, film emulation)
- Heavy vignetting
- Any look that screams "I color graded this"

The goal is "phone on auto" not "edited in DaVinci."

### 2. Grain and texture

AI video is unnervingly smooth. Real video has noise, especially in low light.

**Do this:**
- Add fine grain (not film grain — digital sensor noise)
- Match grain intensity to lighting: more grain in shadows and low-light, less in bright daylight
- Grain should be subtle enough that you wouldn't notice it — but you'd notice its absence

**Parameters (ffmpeg example):**
```bash
# Add subtle digital noise
ffmpeg -i input.mp4 -vf "noise=alls=8:allf=t+u" -c:a copy output.mp4

# Lighter grain for well-lit scenes
ffmpeg -i input.mp4 -vf "noise=alls=4:allf=t+u" -c:a copy output.mp4
```

### 3. Skin imperfections

AI skin is too smooth. Even with "realistic" prompts, Sora produces skin that looks retouched.

**In prompts:** Include "visible pores, natural skin texture, minor imperfections" — not "beautiful skin" or "flawless complexion."

**In post:** If skin still looks too clean, very light grain focused on skin-tone areas helps. Don't overdo it.

### 4. Frame rate consistency

Mismatched frame rates between clips in a sequence are an immediate tell.

**Lock frame rate across all clips in a campaign:**
- 30fps for phone-realistic UGC (most common)
- 24fps only if deliberately going for a "cinematic" phone look (some newer phones shoot 24)
- Never mix frame rates within one final video

```bash
# Standardize to 30fps
ffmpeg -i input.mp4 -r 30 -c:a copy output_30fps.mp4
```

### 5. Resolution pipeline

**The 4K trick:** Upscale to 4K, add grain at 4K, then re-export at target resolution. This embeds the grain into the image data instead of sitting on top of it. The grain becomes part of the texture, not a filter.

```bash
# Upscale to 4K
ffmpeg -i input.mp4 -vf "scale=3840:2160:flags=lanczos" upscaled.mp4

# Add grain at 4K
ffmpeg -i upscaled.mp4 -vf "noise=alls=6:allf=t+u" upscaled_grain.mp4

# Re-export at 1080p
ffmpeg -i upscaled_grain.mp4 -vf "scale=1080:1920:flags=lanczos" final_1080.mp4
```

### 6. Audio realism

Clean audio is the biggest audio tell. Real UGC has room tone, background noise, slight echo.

**For voice (if using voice clone or TTS):**
- Add background noise layer: room ambience, not white noise
- Slight room reverb (small room, not cathedral)
- Occasional background sounds: AC hum, distant traffic, someone in another room
- Compression artifacts — real phone mics compress audio aggressively
- Slightly uneven volume (people move closer and further from phone mic)

**For environment audio:**
- Match the visual setting: kitchen has fridge hum, bedroom has silence + occasional outside sound
- If the video shows a coffee shop, add coffee shop ambience
- Never use music unless it's clearly playing from a speaker in the scene (phone speaker, car radio)

**What kills it instantly:**
- Studio-clean voice with zero room tone
- Perfect consistent volume throughout
- Any background music that sounds "placed"
- Voiceover quality that's clearly not recorded on a phone

### 7. Lighting consistency

Across clips in a sequence, lighting must match:
- Same color temperature (warm indoor, cool daylight, mixed fluorescent)
- Same direction (window light from left in clip 1 must be from left in clip 2)
- Same intensity (don't go from dim bedroom to brightly lit bedroom between cuts)

When extending clips or stitching segments, explicitly describe the lighting state in every prompt.

## Post-production checklist

Before any clip is "done":
- [ ] Color grade applied (reduced contrast, lifted shadows, slight fade)
- [ ] Grain added (appropriate to lighting conditions)
- [ ] Frame rate standardized (30fps default)
- [ ] Audio has room tone / background noise
- [ ] Lighting consistent across all clips in sequence
- [ ] Skin doesn't look retouched
- [ ] Final export at target resolution
- [ ] Watched on phone screen (not just monitor) — this is where the audience sees it

## The phone test

Final quality check: AirDrop or send the video to your phone. Watch it on the phone screen, in the app where it'll be posted, scrolling past it like a normal user. If anything pings as "AI" in that context, fix it.

Monitor viewing is misleading. Phone-screen-in-feed is the only test that matters.
