# Green Zone — Platform Safe Areas

Pixel-precise safe zones for text overlays. Text outside these areas gets blocked by platform UI (profile icons, captions, share buttons, search bars).

## Universal safe zone (works on all platforms)

On a 1080x1920 canvas:
- **X:** 60 – 960 (leave 60px margins on both sides)
- **Y:** 210 – 1480 (avoid top 210px and bottom 440px)

On a 720x1280 canvas (scale proportionally):
- **X:** 40 – 640
- **Y:** 140 – 987

## Platform-specific zones

### TikTok (9:16, 1080x1920)
| Area | Pixels | What's there |
|------|--------|-------------|
| Top 0-150 | blocked | Search bar, "Following/For You" tabs |
| Top 150-210 | risky | Close to UI elements |
| Right 960-1080 | blocked | Like, comment, share, bookmark buttons |
| Bottom 1480-1700 | blocked | Username, caption text |
| Bottom 1700-1920 | blocked | Navigation bar |

### Instagram Reels (9:16, 1080x1920)
| Area | Pixels | What's there |
|------|--------|-------------|
| Top 0-200 | blocked | Status bar, camera/DM icons |
| Right 960-1080 | blocked | Like, comment, share, save buttons |
| Bottom 1500-1920 | blocked | Username, caption, audio, nav bar |

### YouTube Shorts (9:16, 1080x1920)
| Area | Pixels | What's there |
|------|--------|-------------|
| Top 0-180 | blocked | Status bar, search |
| Right 960-1080 | blocked | Like, dislike, comment, share |
| Bottom 1500-1920 | blocked | Title, channel, nav bar |

## Text placement rules

- **Hook text:** center of safe zone, vertically around Y 400-600 (upper-middle)
- **Body captions:** lower portion of safe zone, Y 900-1200
- **Never stack more than 3 lines** — anything more is unreadable at scroll speed
- **3-7 words per line** — more than 7 gets too small to read
- **Lowercase is fine** — feels more authentic than ALL CAPS
- **Font size:** 54-64px on 1080p, 36-42px on 720p

## Font

**TikTok Sans** — TikTok's official open-source font (SIL license). Use this for TikTok-native look.
**Helvetica Neue Bold** or **SF Pro** — for Instagram-native look.

For maximum cross-platform compatibility, use **bold sans-serif, white text, with either a semi-transparent black background box (TikTok style) or black outline with drop shadow (Instagram style).**

## Hook text templates

Proven templates ranked by engagement:

| Template | Best for | Example |
|----------|----------|---------|
| "When [relatable situation]..." | Problem-agitate | "When your gym software can't handle a data migration..." |
| "POV: [emotional scenario]" | Identity/empathy | "POV: you're a gym owner doing billing at 11pm" |
| "[Stat] people [behavior]" | Authority/shock | "86% of gym owners quit in year 2" |
| "Nobody talks about [truth]" | Insider knowledge | "Nobody talks about what happens after you open a gym" |
| "I wish someone told me [lesson]" | Regret/wisdom | "I wish someone told me coaching was the easy part" |
| "[Age/role] and still [struggle]" | Relatability | "3 years in and still chasing failed payments at midnight" |

**Rules:** 3-7 words per line. Max 3 lines. Relatable beats clever. Lowercase is OK.
