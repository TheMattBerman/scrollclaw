# Video Orchestrator: Sora + Kling

Two engines, one pipeline. Sora handles A-roll (talking head, synced dialogue). Kling handles B-roll (product shots, contextual scenes, demonstrations). They combine in post.

## Why two engines

**Sora 2 excels at:**
- Talking head with synced audio — lip sync from dialogue text
- First-frame image-to-video with character preservation
- Conversational, confessional, direct-to-camera energy
- Single sustained shots (4-12 seconds of continuous motion)

**Sora 2 struggles with:**
- Product interaction (holding, demonstrating, using specific products)
- Multiple elements in frame (product + person + environment details)
- Consistent brand elements across shots
- Character doing complex physical actions

**Kling 3 excels at:**
- Element system — lock character AND product identity across shots
- Multi-prompt sequences — choreographed shot progressions in one generation
- Product-in-hand, product-on-surface, product-in-use scenes
- B-roll beauty shots, demos, contextual imagery

**Kling 3 struggles with:**
- Natural-sounding dialogue delivery (voice IDs are inconsistent)
- The ultra-casual UGC talking-head feel (tends more polished)

## The A/B-roll split

### A-roll: Sora 2
The creator talking to camera. This is the anchor footage.

| What | How |
|------|-----|
| Talking head clips | Nano Banana first frame → Sora i2v with dialogue in prompt |
| Direct-to-camera confession | Structured motion prompt (Camera/Subject/Dialogue/Audio/Environment/Style) |
| Reaction shots | First frame with expression → Sora i2v with subtle motion |
| Opening/closing address | Same creator, same setting, different energy |

### B-roll: Kling 3
Everything that supports the story but doesn't have the creator talking to camera.

| What | How |
|------|-----|
| Product close-ups | @Element2 (product) in contextual setting |
| Product in use | @Element1 (character) + @Element2 (product) interaction |
| Environment establishing shots | Setting without character, mood-building |
| Screen/dashboard demos | @Element2 (screenshot) on phone/laptop in scene |
| Before/after scenes | @Element1 in "before" vs "after" state |
| Mechanism bridge imagery | Contextual visuals matching voiceover content |

## Orchestration workflow

### Phase 1: Assets
1. Build creator profile (identity lock + voice personality)
2. Generate character reference image with Nano Banana → this becomes **both:**
   - Sora first frame source
   - Kling @Element1 reference
3. Get product images → Kling @Element2
4. Write the full script with A/B-roll markers

### Phase 2: Script with A/B-roll markers

Mark the script for which engine handles each section:

```
[A-ROLL: Sora — talking head, car, hook]
"so I'm sitting in my car right now… and I know that 
sounds weird but like… this is the first time in three 
years I'm leaving at a normal hour."

[A-ROLL: Sora — talking head, car, problem]
"I used to be in that back office until ten, eleven at 
night. not coaching. not programming. chasing people 
for money."

[B-ROLL: Kling — back office, billing screen]
(Show: cluttered back office, laptop open with billing 
dashboard, @Element1 character hunched over keyboard, 
late at night. Overhead fluorescent light.)

[B-ROLL: Kling — phone notification montage]  
(Show: phone screen with failed payment notifications, 
@Element2 app dashboard showing resolved payments. 
Close-up, hands holding phone.)

[A-ROLL: Sora — talking head, car, realization]
"a buddy told me about this app… and I was like sure, 
another one. but um. failed payments just handled 
themselves overnight. I didn't get a single text."

[B-ROLL: Kling — product in use, calm]
(Show: @Element1 character walking out of gym, keys in 
hand, parking lot, normal hour. @Element2 app visible 
on phone briefly. Evening light, not late night.)

[A-ROLL: Sora — talking head, car, close]
"anyway. I'm going home. that's — yeah. that's the 
whole thing."
```

### Phase 3: Generate A-roll (Sora)
Generate each A-ROLL section as a separate Sora clip:
1. First frame for each clip (may reuse same frame or generate angle variations)
2. Structured motion prompt with dialogue
3. Download and save immediately

### Phase 4: Generate B-roll (Kling)
Generate each B-ROLL section via Kling 3:
1. Use character Element reference (same face as Sora clips)
2. Product Element for product shots
3. Multi-prompt for sequences
4. Queue endpoint for anything over 5s

### Phase 4.5: Last-frame stitching (for multi-clip continuity)
When stitching Sora A-roll clips (e.g., two 12s clips for a 24s podcast):
1. Generate clip 1 normally (first frame → Sora i2v)
2. Extract last frame of clip 1: `ffmpeg -sseof -0.1 -i clip1.mp4 -frames:v 1 last-frame.png`
3. Use that last frame as the first frame of clip 2
4. This creates seamless visual continuity — same pose, same lighting, same expression at the cut point
5. ffmpeg concat joins them without a visible seam

This is better than using the same original first frame for both clips (which can create a jarring jump back to the starting position).

### Phase 5: Assembly (order matters — tested)

```
1. Normalize all clips to same resolution (720x1280)
2. Cut A-roll at script beat points (where B-roll cuts in)
3. Stitch video segments (A-roll + B-roll, video only, no audio)
4. Mix audio: Sora voice (from A-roll) + B-roll ambient (delayed to B-roll start, ~15% volume)
5. Post-production pass (color grade, grain, frame rate)
6. Captions LAST (after post-production — grain degrades caption pills if applied after)
```

**The order of steps 5 and 6 is critical.** Post-production first, captions last. Tested: applying captions before post-production causes grain/color grade to blur the clean caption pills.

## Kling 3 API

See `references/sora-api.md` for complete endpoint reference with verified field names.

### Quick reference (fal.ai — primary, tested)

```bash
# i2v with character face as start frame
curl -s -X POST "https://queue.fal.run/fal-ai/kling-video/v3/pro/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "...", "start_image_url": "https://...", "duration": 5, "aspect_ratio": "9:16", "generate_audio": true}'

# t2v faceless B-roll (no face reference needed)
curl -s -X POST "https://queue.fal.run/fal-ai/kling-video/v3/pro/text-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "...", "duration": 5, "aspect_ratio": "9:16", "generate_audio": true}'
```

**Critical field name:** `start_image_url` (NOT `start_image`) on fal.ai.

### Kling on Replicate (fallback)

Use `kwaivgi/kling-v3-omni-video` for `reference_images` + `<<<image_N>>>` template support. Field name is `start_image` (NOT `start_image_url`) on Replicate.

### Speed advantage
Kling generates in ~100s vs Sora's 5-10 min. Use Kling for all B-roll.

## B-roll environment matching (tested — critical for quality)

**Kling B-roll generated from text prompts alone looks like stock footage.** It creates a generic version of the scene that doesn't match the A-roll's specific environment — different floor, different lighting, different color temperature. This breaks immersion immediately.

**The fix:** Extract a frame from the A-roll video and use it as Kling's `start_image_url`. Kling then generates the B-roll scene starting FROM the A-roll's actual environment — same floor, same lighting, same color world.

```bash
# Extract a frame showing the environment (not the face)
ffmpeg -i aroll.mp4 -ss 7 -frames:v 1 kitchen-frame.png

# Use as Kling start frame
curl -X POST "https://queue.fal.run/fal-ai/kling-video/v3/pro/image-to-video" \
  -d '{"prompt": "dog eating from bowl on kitchen floor...", "start_image_url": "kitchen-frame.png", ...}'
```

Pick a frame that shows the environment clearly — floor, lighting, background objects. The A-roll frame anchors Kling to the right visual world.

## Color consistency across engines

Sora and Kling produce different color profiles. This must be corrected in post:

1. **Establish the look from Sora A-roll** — the talking head sets the color world
2. **Grade Kling B-roll to match** — adjust saturation, contrast, temperature
3. **Apply shared grain layer** — same grain profile across all clips
4. **Match shadow density** — Sora tends darker shadows, Kling tends lifted

The post-production pass from `post-production.md` handles this, but pay special attention to cross-engine matching.

## Character consistency across engines

The same person must look the same in Sora clips and Kling clips:

1. **Generate MULTIPLE context-specific first frames** with Nano Banana — one per setting
   - Podcast frame: headphones, mic, studio lighting
   - Gym frame: polo, gym environment, practical lighting
   - Car frame: hoodie, dashboard glow
   - Back office frame: desk, laptop, overhead fluorescent
2. **Use the right frame for the right clip** — don't feed the podcast frame into a gym B-roll shot (headphones in a gym makes no sense)
3. **Lock identity traits** across all frames — same face, same build, same distinguishing features. Only wardrobe and environment change.
4. **Review across all clips** before assembly — flag any drift

The creator profile's prompt invariants go into every Nano Banana first-frame generation to keep the face consistent. The wardrobe and environment change per scene.

## Product screenshots and phone UI in B-roll

AI cannot generate realistic app screens, UI, or text. It will always look garbled and fake.

**For product/app shots:**
1. **Use real screenshots** — capture the actual app/dashboard
2. **Composite in post** — generate the hands-holding-phone B-roll, then overlay the real screenshot onto the phone screen area
3. **Or use as Kling reference image** — pass the real screenshot as `start_image_url` so Kling places it in context
4. **Never rely on AI to generate UI text** — it will always look wrong

**For notification-style B-roll (phone buzzing with alerts):**
- Generate the physical scene (hands, phone, desk, lighting) with Kling
- The phone screen content should look like **native iPhone UI** — not generic app screens
- Best approach: composite a real iPhone notification screenshot onto the phone screen in post
- If generating with AI, prompt for "phone screen lighting up" without specifying text content — let the glow be the content, not readable text

**For any B-roll showing screens, dashboards, text on devices:**
- Screen recording of the real product + composite onto generated device scene
- This is a post-production step, not a generation step

## Audio orchestration

B-roll is visual only. The voice track from A-roll runs continuously — never muted, never interrupted.

See `references/audio-orchestration.md` for the full pipeline: A-roll stitch → ElevenLabs S2S → segment → insert B-roll visuals → final mix.
