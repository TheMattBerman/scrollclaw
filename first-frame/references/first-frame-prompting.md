# First-Frame Prompting

Nano Banana defaults to an AI aesthetic — smooth skin, grey-scale color, perfect composition, studio-quality lighting. None of that looks like UGC. This reference forces the model toward iPhone-camera realism.

## The photorealism pre-prompt

Include this block at the START of every first-frame prompt, before the color JSON and scene description:

```
Raw iPhone 15 Pro photo. Candid moment, unfiltered, authentic.
f/1.8 aperture, shallow depth of field, slight digital sensor grain.

REALISM RULES:
- Natural imperfections: visible skin texture and pores, flyaway hairs, slight facial asymmetry
- Under-eye area shows natural shadows, not concealed
- Hands have 5 fingers in natural positions (not posed)
- Environment has real clutter, not styled
- Lighting is practical (window, lamp, overhead, screen glow) — never studio, never ring light
- Expression is candid mid-moment, not posed for camera
- Slight motion blur acceptable on hands/movement
- Color is phone-auto, not graded

Negative prompt: CGI, 3D render, perfect skin, plastic, beauty filter, symmetrical face, studio lighting, fake, artificial, dead eyes, model pose, photoshoot, ring light, retouched, airbrushed, stock photo, Shutterstock
```

## The three-layer prompt structure

Every first-frame prompt has three layers in this order:

### Layer 1: Photorealism pre-prompt (above)
Forces iPhone-camera realism. Always the same block.

### Layer 2: Color reference JSON (from color-reference-system.md)
Sets the specific color world for this scene. Varies per environment.

### Layer 3: Scene description
Character identity + environment + action + composition. This is where the creator profile's prompt invariants go.

### Full prompt example

```
Raw iPhone 15 Pro photo. Candid moment, unfiltered, authentic.
f/1.8 aperture, shallow depth of field, slight digital sensor grain.

REALISM RULES:
- Natural imperfections: visible skin texture and pores, flyaway hairs, slight facial asymmetry
- Under-eye area shows natural shadows, not concealed
- Hands have 5 fingers in natural positions
- Environment has real clutter, not styled
- Lighting is practical — never studio, never ring light
- Expression is candid mid-moment, not posed
- Color is phone-auto, not graded

Negative prompt: CGI, 3D render, perfect skin, plastic, beauty filter, symmetrical face, studio lighting, fake, artificial, dead eyes, model pose, ring light, retouched, airbrushed, stock photo

Use this visual reference as the color grading foundation:
{"color_grading":{"overall_tone":"cool-warm split","shadows":{"color":"deep blue-grey"},...},"lighting":{...},"texture":{"grain":"heavy digital noise — phone in low light",...}}

Scene: A male gym owner, age 37-41, square face, medium-warm skin tone. Short dark brown hair, slightly messy, receding at temples. 2-3 day stubble. Athletic build, forearm tattoo. Slight bags under eyes, looks tired. Normal-looking, not model-pretty.

Sitting in driver's seat of parked car at night. Dark charcoal polo, hoodie unzipped. Looking at phone camera propped on dashboard — slight upward angle, off-center. Expression: reflective, mildly exhausted, half-smile starting. Car interior: phone mount, empty coffee cup, gym bag on passenger seat, keys on rearview. Blurred gym sign through windshield.

iPhone selfie-camera. Handheld. Not composed, not professional. This looks like a real person who hit record at 9pm in a parking lot.
```

## iPhone model specifics

Match the iPhone model to the creator's demographic:

| Creator type | iPhone model | Why |
|-------------|-------------|-----|
| Budget-conscious / younger | iPhone 13 or 14 | Slightly lower quality, more grain, realistic for the demographic |
| Standard / mid-range | iPhone 15 | Current standard, good balance |
| Pro / tech-savvy / higher income | iPhone 15 Pro or 16 Pro | Sharper, but specify "auto mode" not "ProRAW" |

This matters because different iPhone models produce noticeably different image qualities. A gym owner probably has a 14 or 15, not a 16 Pro Max.

## Physical imperfection checklist

Before submitting any first-frame prompt, verify you've included:

- [ ] Visible skin texture and pores (not smooth)
- [ ] Natural under-eye shadows
- [ ] Flyaway hairs or slightly messy hair
- [ ] Slight facial asymmetry
- [ ] Realistic hands (5 fingers, natural pose)
- [ ] Environment clutter (specific items, not "messy")
- [ ] Practical light source named (not "dramatic" or "studio")
- [ ] "Candid moment" or "mid-moment" (not posed)
- [ ] Negative prompt included (CGI, 3D render, perfect skin, etc.)
- [ ] iPhone model specified

## What makes AI images look AI

The specific tells this system fights:

1. **Skin smoothing** — AI removes all pores and texture by default. Counter with "visible skin texture and pores, natural imperfections."
2. **Symmetrical faces** — AI makes faces too symmetrical. Counter with "slight facial asymmetry."
3. **Perfect hair** — AI makes every hair strand behave. Counter with "flyaway hairs, slightly messy."
4. **Dead eyes** — AI eyes lack the micro-moisture and light variation of real eyes. Counter with "natural catch lights, slightly moist eyes" and the negative prompt.
5. **Studio lighting** — AI defaults to even, wrap-around light. Counter by naming a specific practical light source and its direction.
6. **Grey color cast** — The Nano Banana default. Counter with the color reference JSON system.
7. **Too-clean environments** — AI backgrounds are spotless and styled. Counter with specific clutter items.
8. **Perfect composition** — AI centers subjects and balances frames. Counter with "off-center, not composed, phone propped at angle."

## Iteration guidance

Expect to generate 2-4 versions of frame 1 before getting one that passes. This is normal. Evaluate each against the checklist above. Common iteration patterns:

- First attempt too smooth → strengthen "visible pores, skin texture" language
- First attempt too grey → add or adjust color reference JSON
- First attempt too composed → add "off-center, phone propped, not professional"
- First attempt character doesn't match → tighten identity spec, add more distinguishing details
- First attempt environment too clean → add 3-4 specific clutter items by name
