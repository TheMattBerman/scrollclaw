# Creator System

Persistent AI creator identities for UGC campaigns. Each creator is a reusable character with locked visual traits and voice personality.

## What to lock per creator

Every creator profile must specify:

### Visual identity (non-negotiable)
- **label** — working name (e.g., "Maya", "Coach Dan")
- **age band** — specific range, not "young" (e.g., 28-32)
- **gender presentation**
- **face shape** — round, angular, oval, square
- **skin tone** — specific (medium-warm olive, light with freckles)
- **hair** — cut, color, texture, length. Lock this hard. AI loves changing hair.
- **facial hair** — state must be explicit even if "none / clean-shaven." AI adds beards randomly.
- **build** — average, athletic, slim, stocky. Not model-proportioned unless the brand calls for it.
- **distinguishing features** — glasses, tattoo on left forearm, gap tooth, scar on chin. These anchor identity.
- **realism note** — "normal-looking, not model-pretty" is almost always right for UGC

### Wardrobe family
- **default outfit** — what they'd wear in most clips (e.g., oversized vintage tee, joggers)
- **alt outfits** — 2-3 variations within the same vibe (different color tee, hoodie swap)
- **never wears** — things that break character (suit and tie, activewear if they're a desk worker)

### Environment family
- **primary setting** — where most clips happen (bedroom, kitchen counter, car)
- **alt settings** — 1-2 secondary locations (coffee shop, office desk, gym parking lot)
- **clutter notes** — what's visible in background (specific items, not "messy")

### Voice personality
- **speaking energy** — low-key, enthusiastic, deadpan, anxious
- **verbal tics** — filler words, restarts, particular phrases
- **opinion style** — blunt, measured, skeptical, accidentally funny
- **script register** — lowercase stream of consciousness, half-sentences, or full sentences with personality

### ElevenLabs voice model
- voice_id (custom — never use library voices)
- Source: voice design or instant clone
- If cloned: reference source description
- Room tone preset: which ambient layer matches this creator's primary environment

### Sora character_id
Once a character is registered with Sora 2, store the `character_id` here for reuse across all clips.

## Creator profile template

```markdown
# Creator: [Name]

## Visual Identity
- Age band:
- Gender presentation:
- Face shape:
- Skin tone:
- Hair:
- Facial hair:
- Build:
- Distinguishing features:
- Realism: normal-looking, not model-pretty

## Wardrobe
- Default:
- Alt 1:
- Alt 2:
- Never wears:

## Environment
- Primary:
- Alt 1:
- Alt 2:
- Background clutter:

## Voice
- Speaking energy:
- Verbal tics:
- Opinion style:
- Script register:

## Voice
- ElevenLabs voice_id:
- Model version: v3
- Source: voice design / instant clone
- Clone source:
- Room tone preset:

## Sora
- character_id:
- created_at:
- last_used:

## Prompt Invariants
Always include in every prompt for this creator:
- [copy the locked visual traits as a reusable prompt block]
```

## Continuity rules

### Within a single video
- Same person, same wardrobe, same environment throughout
- If the video has multiple scenes (extension chain), wardrobe stays unless there's a clear time jump
- Camera angle changes between segments, never duplicate framing

### Across a campaign
- Same person always (character_id handles this)
- Wardrobe can change between clips (different day)
- Environment can change between clips (different location)
- Voice personality stays consistent

### Across campaigns
- Visual identity stays locked (that's the whole point)
- Wardrobe family can evolve (seasonal, brand evolution)
- New environments are fine
- Voice personality is the deepest constant — harder to drift than visuals

## Anti-drift checklist

Before submitting any prompt, verify:
- [ ] Age band specified
- [ ] Hair described (cut + color + texture)
- [ ] Facial hair state explicit (even if "none")
- [ ] Build described
- [ ] Skin tone specified
- [ ] Distinguishing features included
- [ ] Wardrobe locked for this scene
- [ ] Environment clutter specified
- [ ] "Not model-pretty" or equivalent realism note included
- [ ] character_id included if available

## First-frame generation for creators

When establishing a new creator, generate 3-5 still frames with Nano Banana 2 first. Pick the best one as the canonical reference. Use that reference for:
1. Registering the Sora character_id
2. All future i2v first frames (consistent starting point)
3. Visual reference in the creator profile

This is more reliable than hoping text-to-video nails the creator's look on the first try.
