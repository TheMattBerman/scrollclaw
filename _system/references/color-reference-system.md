# Color Reference System

Nano Banana's default output has a grey-scale color grade that immediately looks AI-generated to anyone who's seen enough AI images. This system fixes that by extracting color grading from real reference images and injecting it as structured JSON into prompts.

## The problem

Text prompts like "warm lighting, golden hour, soft shadows" produce generic interpretations. Every AI model has its own default aesthetic that leans grey, flat, and obviously generated. Describing color in natural language is imprecise — "warm" means different things to different models.

## The fix: JSON color prompts

Instead of describing color in text, extract the exact color profile from a reference image and pass it as structured data.

### Step 1: Find a reference image

Find an image with the exact aesthetic, lighting, and color grading you want. Sources:
- Pinterest (save manually — browse for aesthetic/mood/lighting references)
- Competitor UGC that looks real
- Actual phone photos with the right vibe
- Stock photography with natural color grading
- Screenshots from videos with the right look

The reference image doesn't need to match your content — it just needs to have the right color world.

### Step 2: Extract the color JSON

Upload the reference image to a vision model with strong analytical capabilities. Use a thinking/reasoning model for better analysis.

Prompt:
```
Analyze this image and create a detailed JSON prompt that captures all the visual properties needed to recreate this exact aesthetic. Include:

{
  "color_grading": {
    "overall_tone": "",
    "shadows": {"color": "", "density": "", "warmth": ""},
    "midtones": {"color": "", "saturation": ""},
    "highlights": {"color": "", "intensity": "", "bloom": ""},
    "contrast": "",
    "saturation_level": "",
    "color_temperature": "",
    "dominant_colors": [],
    "color_cast": ""
  },
  "lighting": {
    "source": "",
    "direction": "",
    "quality": "",
    "intensity": "",
    "fill_light": "",
    "ambient": "",
    "specular_highlights": ""
  },
  "texture": {
    "grain": "",
    "sharpness": "",
    "skin_rendering": "",
    "surface_quality": ""
  },
  "atmosphere": {
    "mood": "",
    "depth_haze": "",
    "environmental_light": ""
  }
}

Be extremely specific. Use precise color descriptions (not just "warm" — say "warm amber with slight orange shift in highlights"). Describe exactly what makes this image look the way it does.
```

### Step 3: Use the JSON as prompt base

When generating in Nano Banana, structure the prompt as:

```
Use this visual reference as the color grading and lighting foundation:

[paste full JSON here]

Now generate: [your actual scene description — character, environment, action, composition]
```

The JSON handles realism and color grading. The text handles content. This separation gives dramatically better results than pure text prompts.

### Step 4: Save the JSON for reuse

Store successful color JSONs in the campaign workspace:
```
campaigns/<slug>/color-references/
├── warm-indoor-evening.json
├── natural-daylight-bedroom.json
├── overcast-outdoor-casual.json
└── reference-images/
    ├── warm-indoor-evening-ref.jpg
    └── ...
```

Keep the reference image alongside its JSON so you can verify the match and iterate.

## Building a color library

Over time, build a reusable library of color JSONs for common UGC scenarios:

| Scenario | Color profile |
|----------|--------------|
| Bedroom at night | Warm, low contrast, slight orange from lamp light, lifted shadows |
| Kitchen morning | Cool-neutral daylight from window, slight blue in shadows, clean whites |
| Car (parked) | Mixed light — warm dashboard, cool windshield light, slightly flat |
| Bathroom mirror | Overhead fluorescent or warm vanity light, slightly green-shifted, high contrast |
| Coffee shop | Warm ambient, mixed sources, moderate contrast, slightly desaturated |
| Outdoor overcast | Cool flat light, very low contrast, muted colors, soft shadows |
| Outdoor golden hour | Strong warm directional, deep shadows, orange highlights, high saturation |

Each scenario should have 2-3 JSON variants extracted from real reference images.

## Integration with the pipeline

### Prompt structure for first frames

The prompt file combines three layers: photorealism pre-prompt, color JSON, and scene description.

```
[Photorealism pre-prompt — see references/first-frame-prompting.md]

[Color reference JSON]

Scene: [character identity + environment + action + composition]

Negative prompt: [anti-AI markers]
```

The photorealism pre-prompt forces the model toward iPhone-camera output instead of AI-default aesthetic. The color JSON handles grade and lighting. The scene description handles content.

### With Sora animation
The first frame's color grading carries into the Sora i2v animation. Sora will maintain the color world of the input image. This is another reason first-frame control matters — you set the color grade once in the image, and the video inherits it.

### With post-production
Even with good color reference prompts, apply the post-production color grade pass from `post-production.md`. The reference JSON gets you 80% there. Post-production handles the remaining realism details (grain, contrast fine-tuning, shadow lifting).

## Common mistakes

- **Using a cinematic reference** — gorgeous film stills produce gorgeous AI images that look nothing like phone UGC. Use phone photos as references, not cinematography.
- **Using the same JSON for every scene** — a bedroom at night and a kitchen in the morning have completely different color worlds. Match the reference to the setting.
- **Over-specifying** — if the JSON is too detailed and conflicts with the scene description, the model gets confused. Keep the JSON focused on color/lighting/texture, not composition or content.
- **Skipping the reference image** — don't try to write the JSON from scratch. Your eye is better than your vocabulary at identifying what makes a photo look right. Start from a real image every time.
