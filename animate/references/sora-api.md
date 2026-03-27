# Video API Reference

Single source of truth for all video generation endpoints. Based on real testing, not documentation speculation.

**A-roll primary:** fal.ai Sora 2 (talking head with synced dialogue)
**A-roll fallback:** fal.ai Kling 3 (when Sora is unavailable/sunset)
**Final fallback:** Replicate Kling 3 (when fal.ai is down)
**Image generation:** Replicate only (Nano Banana first frames)

---

## fal.ai — Sora 2 (PRIMARY)

### Endpoints

| Use | Endpoint |
|-----|----------|
| Text-to-Video | `fal-ai/sora-2/text-to-video` |
| Text-to-Video Pro | `fal-ai/sora-2/text-to-video/pro` |
| Image-to-Video | `fal-ai/sora-2/image-to-video` |
| Image-to-Video Pro | `fal-ai/sora-2/image-to-video/pro` |
| Create Character | `fal-ai/sora-2/characters` |

### Queue workflow (all endpoints)

```bash
# Submit
curl -s -X POST "https://queue.fal.run/fal-ai/sora-2/text-to-video/pro" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d @payload.json

# Response includes exact URLs to use:
# {
#   "request_id": "...",
#   "status_url": "https://queue.fal.run/fal-ai/sora-2/requests/{id}/status",
#   "response_url": "https://queue.fal.run/fal-ai/sora-2/requests/{id}",
#   "cancel_url": "https://queue.fal.run/fal-ai/sora-2/requests/{id}/cancel"
# }

# Poll — use the EXACT status_url from the response (GET)
curl -s -X GET "$STATUS_URL" -H "Authorization: Key $FAL_KEY"

# Fetch result when COMPLETED (GET)
curl -s -X GET "$RESPONSE_URL" -H "Authorization: Key $FAL_KEY"
# Returns: { "video": { "url": "https://..." }, "video_id": "..." }

# Cancel (PUT)
curl -s -X PUT "$CANCEL_URL" -H "Authorization: Key $FAL_KEY"
```

**CRITICAL:** The status/response URLs use `/fal-ai/sora-2/requests/{id}/...` — NOT the full model path. Always use the URLs returned in the submit response. Do NOT construct them manually.

### Upload files to fal.ai storage

```bash
# Initiate upload
curl -s -X POST "https://rest.alpha.fal.ai/storage/upload/initiate" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"file_name": "frame.png", "content_type": "image/png"}'
# Returns: { "file_url": "https://v3b.fal.media/...", "upload_url": "https://v3b.fal.media/...?signature=..." }

# Upload the actual file
curl -s -X PUT "$UPLOAD_URL" -H "Content-Type: image/png" --data-binary "@file.png"

# Use file_url in API calls
```

### Text-to-Video Pro input schema (verified)

| Field | Type | Required | Values | Notes |
|-------|------|----------|--------|-------|
| prompt | string | yes | free text | Scene description with dialogue |
| duration | enum | no | **4, 8, 12, 16, 20** | Default 4. Pro supports up to 20s. |
| aspect_ratio | enum | no | **"9:16", "16:9"** | Standard ratios, not "portrait"/"landscape" |
| resolution | enum | no | **"720p", "1080p", "true_1080p"** | Default "1080p" |
| character_ids | array of strings | no | char_xxx IDs | Up to 2. **Blocked for AI-generated faces** (Feb 2026 policy). |
| delete_video | boolean | no | true/false | Delete after generation for privacy. Default true. |

### Image-to-Video input schema (verified)

| Field | Type | Required | Values | Notes |
|-------|------|----------|--------|-------|
| prompt | string | yes | free text | Motion/dialogue description |
| image_url | string | yes | URL | First frame image. **Field is `image_url`** not `image` or `input_reference`. |
| duration | enum | no | 4, 8, 12 | i2v may have shorter max than t2v |
| aspect_ratio | enum | no | "9:16", "16:9" | Should match image aspect ratio |
| resolution | enum | no | "720p", "1080p" | Pro only |

### Text-to-Video Pro payload example

```json
{
  "prompt": "Camera: steady podcast camera...\nDialogue: \"...and that is the part nobody talks about...\"",
  "resolution": "1080p",
  "aspect_ratio": "9:16",
  "duration": 12
}
```

### Image-to-Video Pro payload example

```json
{
  "prompt": "The man begins speaking into the microphone, natural gestures...",
  "image_url": "https://v3b.fal.media/files/.../coach-dan-frame.png",
  "resolution": "720p",
  "aspect_ratio": "9:16",
  "duration": 12
}
```

### Timing (from real testing)

| Type | Duration | Generation time |
|------|----------|----------------|
| t2v Pro 720p 4s | 4s | ~4 min |
| t2v Pro 720p 12s | 12s | ~5-6 min |
| i2v Standard 12s | 12s | ~8-10 min |
| i2v Pro 12s | 12s | ~8-10 min |
| t2v Pro 1080p 20s | 20s | May timeout (~15+ min) |

**Recommendation:** Use 720p for testing, 1080p for final. 12s is the sweet spot — 20s at 1080p is unreliable on fal.ai's queue.

### Character IDs (blocked for AI UGC)

The `fal-ai/sora-2/characters` endpoint exists but **blocks AI-generated faces** due to OpenAI's Feb 2026 moderation policy. Input: `{video_url, name}`. Fails with "Character upload failed due to violation of our moderation policies." No workaround exists for synthetic characters.

---

## fal.ai — Kling 3 (A-ROLL FALLBACK)

Auto-fallback when Sora fails or is sunset. Use `--provider kling` to skip Sora entirely.

**Key difference from B-roll usage:** A-roll requires `generate_audio: true` for dialogue lip-sync. No content safety filter (advantage over Sora).

### Endpoints

| Use | Endpoint |
|-----|----------|
| Text-to-Video Pro | `fal-ai/kling-video/v3/pro/text-to-video` |
| Image-to-Video Pro | `fal-ai/kling-video/v3/pro/image-to-video` |
| Text-to-Video Standard | `fal-ai/kling-video/v3/standard/text-to-video` |
| Image-to-Video Standard | `fal-ai/kling-video/v3/standard/image-to-video` |

### Queue workflow

Same as Sora — submit to full endpoint path, poll using the returned `status_url`.

### Image-to-Video input schema (A-roll)

| Field | Type | Required | Values | Notes |
|-------|------|----------|--------|-------|
| prompt | string | yes | free text | Motion/dialogue description |
| start_image_url | string | yes | URL | **Field is `start_image_url`** not `image_url`. First frame. |
| duration | integer | no | 3-15 | Integer, not enum. Clips >15s are clamped. |
| aspect_ratio | enum | no | "9:16", "16:9", "1:1" | Ignored when start_image_url provided. |
| generate_audio | boolean | **yes for A-roll** | true | **Must be true** — A-roll needs synced dialogue audio. |
| negative_prompt | string | no | free text | What to avoid |

### Text-to-Video input schema (A-roll)

| Field | Type | Required | Values | Notes |
|-------|------|----------|--------|-------|
| prompt | string | yes | free text | Scene + dialogue description |
| duration | integer | no | 3-15 | Integer |
| aspect_ratio | enum | no | "9:16", "16:9", "1:1" | Required for t2v |
| generate_audio | boolean | **yes for A-roll** | true | **Must be true** |
| negative_prompt | string | no | free text | |

### Payload example (A-roll i2v)

```json
{
  "prompt": "Camera: handheld iPhone-style front camera...\nDialogue: \"...and that is the part nobody talks about...\"\n...",
  "start_image_url": "https://v3b.fal.media/files/.../coach-dan-frame.png",
  "duration": 12,
  "aspect_ratio": "9:16",
  "generate_audio": true
}
```

### Duration clamping

Sora supports up to 20s. Kling max is 15s. If a script requests >15s, `generate-clip.sh` automatically clamps to 15s with a warning. For longer clips, use `extend-clip.sh` to chain multiple Kling generations.

### Timing (from real testing)

| Type | Duration | Generation time |
|------|----------|----------------|
| i2v Pro 5s | 5s | ~100s |
| t2v Pro 5s | 5s | ~80s |

Kling is **significantly faster** than Sora (~2 min vs ~5-10 min).

### Response shape

```json
{
  "video": {
    "url": "https://...",
    "content_type": "video/mp4",
    "duration": 12.0
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

**Note:** fal.ai Kling is used for both B-roll and A-roll (as Sora fallback). For A-roll, always set `generate_audio: true`.

| Concept | fal.ai Sora | fal.ai Kling | Replicate Sora | Replicate Kling Omni |
|---------|------------|-------------|---------------|---------------------|
| First frame image | `image_url` | `start_image_url` | `input_reference` | `start_image` |
| Duration | `duration` (int enum: 4,8,12,16,20) | `duration` (int: 3-15) | `seconds` (int enum: 4,8,12) | `duration` (int: 3-15) |
| Aspect ratio | `"9:16"` / `"16:9"` | `"9:16"` / `"16:9"` / `"1:1"` | `"portrait"` / `"landscape"` | `"9:16"` / `"16:9"` |
| Quality tier | `resolution`: "720p"/"1080p" | N/A (use pro endpoint) | `resolution`: "standard"/"high" | `mode`: "standard"/"pro" |
| Character refs | `character_ids` (blocked) | N/A | N/A | `reference_images` + `<<<image_N>>>` |
| Audio | always on (Sora) | `generate_audio` (**true for A-roll**, false for B-roll) | always on (Sora) | `generate_audio` (**true for A-roll**) |

---

## Cost awareness

- **fal.ai Sora 2 Pro:** $0.30/sec (720p), $0.50/sec (1080p)
- **fal.ai Kling:** check current pricing
- **Replicate:** per-prediction billing, check dashboard
- **Nano Banana first frames:** much cheaper than video — iterate on frame 1 before committing
- Start with 720p and 4-8s clips to validate, upgrade for final renders
