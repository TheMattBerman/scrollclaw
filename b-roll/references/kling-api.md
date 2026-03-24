# Video API Reference

# Video API Reference

Single source of truth for all video generation endpoints. Based on real testing, not documentation speculation.

**Primary provider:** fal.ai (better features, longer duration, correct field names)
**Fallback provider:** Replicate (Nano Banana first frames, backup for Sora/Kling)

---

## fal.ai — Kling 3 (B-ROLL)

### Endpoints

| Use | Endpoint |
|-----|----------|
| Text-to-Video Pro | `fal-ai/kling-video/v3/pro/text-to-video` |
| Text-to-Video Standard | `fal-ai/kling-video/v3/standard/text-to-video` |
| Image-to-Video Pro | `fal-ai/kling-video/v3/pro/image-to-video` |
| Image-to-Video Standard | `fal-ai/kling-video/v3/standard/image-to-video` |

### Queue workflow

Same pattern as Sora — submit to full endpoint path, poll using the returned status_url.

```bash
# Submit
curl -s -X POST "https://queue.fal.run/fal-ai/kling-video/v3/pro/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d @payload.json

# Poll/fetch uses: /fal-ai/kling-video/requests/{id}/status
# Use the exact URLs from the submit response
```

### Image-to-Video input schema (verified from real testing)

| Field | Type | Required | Values | Notes |
|-------|------|----------|--------|-------|
| prompt | string | yes | free text | Scene description |
| start_image_url | string | yes | URL | **Field is `start_image_url`** not `start_image`. First frame. |
| duration | integer | no | 3-15 | Integer, not string. |
| aspect_ratio | enum | no | "9:16", "16:9", "1:1" | Ignored when start_image_url provided. |
| generate_audio | boolean | no | true/false | Default false. Set true for ambient B-roll sound. |
| negative_prompt | string | no | free text | What to avoid |

### Text-to-Video input schema

| Field | Type | Required | Values | Notes |
|-------|------|----------|--------|-------|
| prompt | string | yes | free text | Scene description |
| duration | integer | no | 3-15 | Integer |
| aspect_ratio | enum | no | "9:16", "16:9", "1:1" | Required for t2v |
| generate_audio | boolean | no | true/false | Default false |
| negative_prompt | string | no | free text | |

### Payload examples (verified)

**i2v with character face as start frame:**
```json
{
  "prompt": "A man hunched over a laptop in a cluttered back office behind a gym...",
  "start_image_url": "https://v3b.fal.media/files/.../coach-dan-face.png",
  "duration": 5,
  "aspect_ratio": "9:16",
  "generate_audio": true
}
```

**t2v faceless B-roll:**
```json
{
  "prompt": "Close-up of hands holding a smartphone showing a clean app dashboard...",
  "duration": 5,
  "aspect_ratio": "9:16",
  "generate_audio": true
}
```

### Timing (from real testing)

| Type | Duration | Generation time |
|------|----------|----------------|
| i2v Pro 5s | 5s | ~100s |
| t2v Pro 5s | 5s | ~80s |

Kling is **significantly faster** than Sora — ~2 min vs ~5-10 min. Use Kling for all B-roll.

### Response shape

```json
{
  "video": {
    "url": "https://...",
    "content_type": "video/mp4",
    "duration": 5.0
  }
}
```

---

## Replicate (FALLBACK)

### When to use Replicate
- Nano Banana first-frame image generation (not on fal.ai)
- Backup when fal.ai is down
- Kling v3 Omni with `reference_images` + `<<<image_N>>>` templates (if needed)

### Sora 2 on Replicate (limited)

| Field | Values | Notes |
|-------|--------|-------|
| seconds | **4, 8, 12 only** | No 16 or 20 |
| aspect_ratio | **"portrait", "landscape"** | Not "9:16"/"16:9" |
| input_reference | URL | First frame (not `image_url`) |
| resolution | "standard", "high" | Pro only |

```
POST https://api.replicate.com/v1/models/openai/sora-2/predictions
POST https://api.replicate.com/v1/models/openai/sora-2-pro/predictions
Authorization: Token $REPLICATE_API_TOKEN
```

### Kling on Replicate

| Model | Path |
|-------|------|
| Kling v3 | `kwaivgi/kling-v3-video` |
| Kling v3 Omni | `kwaivgi/kling-v3-omni-video` |

Omni has `reference_images` (up to 7) with `<<<image_N>>>` prompt templates. Field name is `start_image` (not `start_image_url`).

### Nano Banana (Replicate only)

| Model | Path | Use |
|-------|------|-----|
| Nano Banana 2 | `google/nano-banana-2` | Default first-frame generation |
| Nano Banana Pro | `google/nano-banana-pro` | Higher quality fallback |

```
POST https://api.replicate.com/v1/models/google/nano-banana-2/predictions
Authorization: Token $REPLICATE_API_TOKEN
```

### Upload files (Replicate)
```bash
curl -s -X POST "https://api.replicate.com/v1/files" \
  -H "Authorization: Token $REPLICATE_API_TOKEN" \
  -F "content=@image.png" -F "content_type=image/png"
# Returns: { "urls": { "get": "https://api.replicate.com/v1/files/..." } }
# Files expire in 24h
```

---


## Content safety filter (all providers)

Applies to Sora (both fal.ai and Replicate). Does NOT apply to Kling.

**Triggers on:**
- Highly specific facial descriptions in motion prompts
- Runs AFTER generation — can fail at 99%
- Error: "The input or output was flagged as sensitive" (E005)

**How to avoid:**
- Keep motion prompts generic about the person — first frame defines appearance
- If blocked, soften prompt and retry
- Character registration is blocked for all AI-generated faces (OpenAI policy)

---

## Field name cheat sheet

The same concept has different field names per provider. This is the #1 source of silent failures.

| Concept | fal.ai Sora | fal.ai Kling | Replicate Sora | Replicate Kling Omni |
|---------|------------|-------------|---------------|---------------------|
| First frame image | `image_url` | `start_image_url` | `input_reference` | `start_image` |
| Duration | `duration` (int enum: 4,8,12,16,20) | `duration` (int: 3-15) | `seconds` (int enum: 4,8,12) | `duration` (int: 3-15) |
| Aspect ratio | `"9:16"` / `"16:9"` | `"9:16"` / `"16:9"` | `"portrait"` / `"landscape"` | `"9:16"` / `"16:9"` |
| Quality tier | `resolution`: "720p"/"1080p" | N/A (use pro endpoint) | `resolution`: "standard"/"high" | `mode`: "standard"/"pro" |
| Character refs | `character_ids` (blocked) | N/A | N/A | `reference_images` + `<<<image_N>>>` |
| Audio | always on (Sora) | `generate_audio` (default false) | always on (Sora) | `generate_audio` (default false) |

---

## Cost awareness

- **fal.ai Sora 2 Pro:** $0.30/sec (720p), $0.50/sec (1080p)
- **fal.ai Kling:** check current pricing
- **Replicate:** per-prediction billing, check dashboard
- **Nano Banana first frames:** much cheaper than video — iterate on frame 1 before committing
- Start with 720p and 4-8s clips to validate, upgrade for final renders
