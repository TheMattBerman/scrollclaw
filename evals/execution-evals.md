# Execution Evals

Benchmark tasks to verify the skill produces correct output at each stage.

## Eval 1 — Persona research
**Input:** "Create UGC for The Pet Pantry, a holistic dog food brand. Target: 35F dog mom in NC."

**Expected:**
- Mines competitor reviews for exact language (not paraphrased)
- Builds a failure timeline (what they tried, why it failed, how it felt)
- Finds a specific transformation moment (scene + sensory detail)
- Documents persona in structured format
- Does NOT skip straight to production

## Eval 2 — Format selection + enforcement
**Input:** "Make a talking head video for FitnessGM"

**Expected:**
- Asks what the user wants to make OR recommends format based on context
- Pulls shot breakdown from format library
- Script maps to EVERY segment (Hook + Show + Verdict for talking head)
- Script is NOT a continuous monologue with no visual structure
- Presents script for approval before generating

## Eval 3 — First frame photorealism
**Input:** Generate a first frame for Coach Dan in his car at night

**Expected:**
- Uses the 3-layer prompt structure (photorealism pre-prompt + color JSON + scene)
- Includes "Raw iPhone 14/15 photo" at the start
- Includes negative prompt (CGI, 3D render, perfect skin, cinematic grading, no text/words/letters)
- Specifies iPhone model appropriate to the creator's demographic
- Results in a frame that passes the "is this AI?" test

## Eval 4 — Audio approach selection
**Input:** "Create a podcast clip with B-roll cutaways"

**Expected:**
- Uses Sora native voice for the talking head clips (NOT ElevenLabs TTS)
- B-roll has ambient audio only
- If multiple Sora clips needed: S2S to unify voices
- Does NOT use TTS for any clip where a face is visible
- Audio description: "clean, natural, close and present" NOT mic gear names

## Eval 5 — B-roll environment matching
**Input:** Generate B-roll of a dog eating in the same kitchen as the A-roll

**Expected:**
- Extracts a frame from the A-roll showing the kitchen environment
- Feeds that frame as Kling's start_image_url
- B-roll matches the A-roll's floor, lighting, color temperature
- Does NOT generate generic/stock-looking B-roll from text prompt alone

## Eval 6 — Assembly order
**Input:** Combine A-roll + B-roll + captions into final video

**Expected order:**
1. Normalize all clips to same resolution
2. Cut A-roll at script beat points
3. Stitch video segments
4. Mix audio (Sora voice + B-roll ambient)
5. Post-production (color grade + grain)
6. Captions LAST

**Fail condition:** Captions applied before post-production (grain degrades pills)

## Eval 7 — Hook Face + Demo format
**Input:** "Make a 15-second hook + demo for a pet food brand"

**Expected:**
- Hook: emotive face (from hook-emotions taxonomy) + caption overlay, 3-5s
- Hard cut to demo
- Demo: real product footage recommended, OR Kling with environment-matched start frame
- Total: 15s max (warns if over)
- Caption style: pill (not wall-of-text style)
- Voice from Sora native if face talks, OR voice continues from hook over demo

## Eval 8 — Wall of Text format
**Input:** "Create a wall of text TikTok about switching dog food"

**Expected:**
- Generates face/scene with Nano Banana
- Animates with Sora (subtle movement — NOT static)
- Caption style: --style wall (white text, drop shadow, NO pill background)
- Text is dense, lowercase, conversational
- Text fills upper 40-60% of frame
- Person is the backdrop, text is the content

## Eval 9 — Multi-brand portability
**Input:** Run the same pipeline for two completely different brands

**Expected:**
- Each brand gets its own persona research, creator profile, visual world
- The system works for both without manual prompt hacking
- Creator profiles have different: appearance, wardrobe, environment, voice personality
- Tested: FitnessGM (gym owner, male, car/office) + Pet Pantry (dog mom, female, kitchen)

## Eval 10 — Virality scoring gate
**Input:** Score a finished video before publishing

**Expected:**
- Uses weighted scoring (hook 20%, scroll-stop 20%, completion 20%)
- Hard gate: hook < 50 = auto NO-GO
- Includes platform context and audience
- Marks audio-dependent criteria if scoring from frames only
- Fix suggestion is specific and implementable, not vague
