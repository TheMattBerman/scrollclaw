---
name: scrollclaw-brand-setup
description: "One-time brand initialization. Given a brand name and URL, researches the brand and generates the three workspace/brand/ files that the rest of the pipeline reads. Run once per brand before any campaign work."
metadata:
  openclaw:
    emoji: "🏷️"
    user-invocable: true
    triggers:
      - "brand setup"
      - "set up a brand"
      - "initialize brand"
      - "new brand"
      - "brand research"
      - "brand init"
      - "setup brand"
      - "brand profile"
---

# Brand Setup

One-time initialization. Run this before your first campaign to populate the three brand files that every other skill reads. After this, you never need GrowthClaw or manual templates.

## What This Does

Given a brand name and website URL, this skill:
1. Scrapes the brand's website for voice, positioning, and product details
2. Checks their social presence for how they actually talk to customers
3. Mines reviews and comments for audience language and pain points
4. Scans 2-3 competitors for positioning gaps
5. Generates three files in `workspace/brand/` that the rest of the pipeline consumes

## Step 1: Collect Inputs

**Required:**
- Brand name
- Website URL (homepage)

**Optional (improve output quality):**
- Social media URLs (X/Twitter, Instagram, TikTok, LinkedIn)
- Competitor names or URLs (2-3)
- Product category or vertical
- Any existing brand guidelines or tone docs

If the user only provides brand name + URL, that's enough. Research fills the gaps.

## Step 2: Research the Brand

Read `references/research-protocol.md` for the full protocol. Summary:

### 2a. Website Scrape
Scrape these pages (in order of priority):
1. **Homepage** — positioning, hero copy, value props, overall energy
2. **About / Our Story** — founding narrative, mission language, personality
3. **Product pages (top 2-3)** — feature language, benefit framing, price positioning
4. **FAQ or Help** — how they talk when being helpful vs selling

Extract: sentence structure, formality level, jargon, banned words (what they avoid), energy (calm vs urgent), humor presence, emoji use.

### 2b. Social Media Scan
Check their active social profiles (X/Twitter and Instagram minimum):
- How do they talk in captions vs replies?
- Do they use emoji? How much?
- Formal or casual? First person or third?
- Do they joke? What kind of humor?
- What hashtags/language patterns repeat?

Focus on the **gap between website copy and social voice** — social is usually more authentic and closer to how a UGC script should sound.

### 2c. Review Mining
Find 15-30 customer reviews from:
- Amazon (if applicable)
- Reddit (search brand name + product category)
- Social media comments (Instagram, TikTok, X)
- Trustpilot / G2 / app store reviews (depending on product type)

Extract:
- Exact phrases customers use to describe the problem ("I was so tired of...")
- Exact phrases for the result ("now I actually...")
- Emotional language — frustration, relief, surprise, delight
- Demographic signals — life stage, context clues, purchase motivations
- Objections and hesitations before buying

### 2d. Competitor Scan
Scan the homepage + positioning of 2-3 competitors:
- What claims do they all make? (these are table stakes, not differentiators)
- What does THIS brand say that competitors don't?
- What positioning gaps exist?
- What audience segments are underserved?

## Step 3: Generate the Three Files

### `workspace/brand/voice-profile.md`

Must include:
- **Tone spectrum:** where the brand sits on formal↔casual, serious↔playful, expert↔peer
- **Energy level:** calm/measured vs urgent/energetic vs somewhere between
- **Sentence patterns:** short and punchy? Long and flowing? Mixed?
- **Vocabulary:** words they love, words they never use
- **What they say vs don't say:** specific phrases the brand uses repeatedly vs language they avoid
- **Example phrases:** 5-10 real phrases pulled from their content that capture the voice
- **UGC calibration:** how the voice should shift for UGC context (slightly more casual, more first-person, more "real talk")

### `workspace/brand/positioning.md`

Must include:
- **One-line positioning:** what they are and for whom, in one sentence
- **Core value props:** 3-5 key benefits in the brand's language
- **Differentiation:** what they claim that competitors don't
- **Competitive landscape:** who they compete with and how they position against each
- **Price positioning:** premium, mid-market, accessible, or value
- **Proof points:** stats, awards, testimonials, social proof they lean on
- **UGC angles:** 2-3 angles that would work for UGC scripting based on their positioning

### `workspace/brand/audience.md`

Must include:
- **Primary ICP:** demographics + psychographics in plain language
- **Life stage and context:** when/why do they buy this? What's happening in their life?
- **Pain points (in customer language):** exact phrases from reviews, not marketing-speak
- **Purchase motivations:** what pushes them from considering to buying?
- **Objections:** what almost stopped them from buying?
- **Language patterns:** how this audience talks about this problem category
- **Creator archetype match:** what kind of UGC creator would this audience trust? (age range, vibe, aesthetic, energy)
- **Anti-patterns:** creator types that would NOT work for this audience

## Step 4: Validate

After generating the three files:

1. **Existence check:** all three files exist in `workspace/brand/`
2. **Substance check:** each file has real, specific content — not just headers with generic filler
3. **Specificity test:** could a script writer use these files without ever visiting the brand's website? If not, the files need more detail
4. **Pre-flight check:** run `bash scripts/pre-flight.sh` brand checks — the brand section should pass

Show the user a summary:

```
🏷️ Brand setup complete: <brand name>

  ✓ workspace/brand/voice-profile.md — <tone summary, e.g. "conversational-direct, no corporate speak">
  ✓ workspace/brand/positioning.md — <one-line positioning>
  ✓ workspace/brand/audience.md — <primary ICP summary>

Files are ready. Run /persona to start your first campaign.
```

## Step 5: Handle Existing Files

If `workspace/brand/` already has files:
- Show what exists and when it was last modified
- Ask the user: **"Brand files already exist. Overwrite, merge, or skip?"**
  - **Overwrite:** replace all three files with fresh research
  - **Merge:** keep existing content, add new findings, flag conflicts
  - **Skip:** abort brand setup, use existing files

Never silently overwrite existing brand files.

## Brand Memory Integration

### Reads
| File | Purpose |
|------|---------|
| Brand's website (scraped) | Voice, positioning, product details |
| Brand's social profiles (scraped) | Authentic voice patterns, engagement style |
| Customer reviews (scraped) | Audience language, pain points, demographics |
| Competitor homepages (scraped) | Positioning gaps, differentiation |

### Writes
| File | Notes |
|------|-------|
| `workspace/brand/voice-profile.md` | Brand voice, tone, vocabulary, example phrases. Read by `/persona` for script calibration. |
| `workspace/brand/positioning.md` | Differentiation, value props, competitive landscape. Read by `/persona` for pain point emphasis. |
| `workspace/brand/audience.md` | ICP, customer language, creator archetype guidance. Read by `/persona` for creator selection. |

### Context loading (show this to the user at session start)

```
🏷️ Brand Setup for: <brand name>
  Input: <brand URL>
  Social: <social URLs if provided, or "will discover">
  Competitors: <competitor names if provided, or "will identify from research">
  Existing brand files: <none / list what exists>
```

## Contract

### Input
- Required: brand name + website URL
- Optional: social media URLs, competitor names/URLs, product category, existing brand guidelines
- Format: plain text (brand name, URLs) provided by user
- Source: user prompt

### Output
- Produces: three brand context files in `workspace/brand/`
- Format: structured markdown files following the schemas defined in Step 3
- Default behavior: research the brand, generate all three files, validate, and present summary
- Downstream use: `/persona` (reads all three files), and indirectly every other pipeline skill

### Validation
- Pre-conditions: brand name and URL are provided; workspace/ directory exists (create if not)
- Post-conditions: all three files exist in `workspace/brand/` with substantive content; pre-flight brand checks pass
- Failure checks: if scraping fails for a source, note it and proceed with available data; never generate files with only headers and no content; if research yields insufficient data, tell the user what's missing and ask for additional input

## Next Step

Brand files populated → run `/persona` to start your first campaign.
