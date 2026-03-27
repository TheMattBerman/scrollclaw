#!/usr/bin/env python3
"""Generate TikTok-native text overlays as transparent PNGs.

Takes a JSON config (or CLI args) with lines, font, size, colors, stroke,
and positioning. Outputs a transparent PNG at the target resolution.

Presets:
  tiktok-wall   — TikTok Sans Regular 38px, muted white, 2.5px black stroke (default)
  tiktok-hook   — TikTok Sans Bold 52px, bright white, 3px stroke
  tiktok-scene  — TikTok Sans Regular 32px, muted white, 2px stroke
  tiktok-dense  — TikTok Sans Regular 28px, muted white, 2px stroke, tighter spacing

Usage:
    # Default wall-of-text preset
    python3 caption-overlay.py \\
        --lines "things i didn't know,would bother me about,my boyfriend..." \\
        --output caption.png

    # Hook preset (bigger, bolder)
    python3 caption-overlay.py \\
        --preset tiktok-hook \\
        --lines "POV: you finally fix,your boyfriend's worst habit" \\
        --output hook.png

    # JSON config for full control
    python3 caption-overlay.py --config captions.json --output caption.png

    # Auto-detect resolution from video
    python3 caption-overlay.py \\
        --video post-produced.mp4 \\
        --lines "the swap that changed everything" \\
        --output overlay.png

JSON config format:
    {
        "lines": ["line one", "line two"],
        "font": "TikTokSans-Regular",
        "size": 38,
        "weight": "regular",
        "fill": [247, 247, 242, 240],
        "stroke_color": [0, 0, 0, 255],
        "stroke_width": 2.5,
        "align": "center",
        "y_start": 280,
        "line_height": 50,
        "width": 720,
        "height": 1280
    }
"""
import argparse
import json
import os
import subprocess
import sys
import urllib.request
import zipfile

# ─────────────────────────────────────────────
# Ensure Pillow is available
# ─────────────────────────────────────────────

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow not found — installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "-q"])
    from PIL import Image, ImageDraw, ImageFont


# ─────────────────────────────────────────────
# Font management
# ─────────────────────────────────────────────

FONT_CACHE_DIR = os.path.expanduser("~/.cache/scrollclaw/fonts")
TIKTOK_SANS_REGULAR = os.path.join(FONT_CACHE_DIR, "TikTokSans-Regular.ttf")
TIKTOK_SANS_BOLD = os.path.join(FONT_CACHE_DIR, "TikTokSans-Bold.ttf")

# Google Fonts CDN for TikTok Sans (available as "TikTok Sans" on Google Fonts)
GOOGLE_FONTS_URL = (
    "https://fonts.google.com/download?family=TikTok+Sans"
)

FALLBACK_FONTS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    "/tmp/fonts/extras/ttf/Inter-SemiBold.ttf",
]


def download_tiktok_sans():
    """Download TikTok Sans from Google Fonts if not cached."""
    if os.path.exists(TIKTOK_SANS_REGULAR) and os.path.exists(TIKTOK_SANS_BOLD):
        return True

    os.makedirs(FONT_CACHE_DIR, exist_ok=True)
    zip_path = os.path.join(FONT_CACHE_DIR, "tiktok-sans.zip")

    print(f"Downloading TikTok Sans from Google Fonts...")
    try:
        urllib.request.urlretrieve(GOOGLE_FONTS_URL, zip_path)
        with zipfile.ZipFile(zip_path, "r") as zf:
            for member in zf.namelist():
                basename = os.path.basename(member)
                if not basename:
                    continue
                # Look for regular and bold variants
                lower = basename.lower()
                if "regular" in lower and lower.endswith(".ttf"):
                    with open(TIKTOK_SANS_REGULAR, "wb") as f:
                        f.write(zf.read(member))
                elif "bold" in lower and lower.endswith(".ttf"):
                    with open(TIKTOK_SANS_BOLD, "wb") as f:
                        f.write(zf.read(member))
        os.remove(zip_path)
        print(f"Cached fonts to {FONT_CACHE_DIR}/")
        return True
    except Exception as e:
        print(f"Warning: could not download TikTok Sans: {e}", file=sys.stderr)
        return False


def find_font(weight="regular"):
    """Find TikTok Sans or fall back to a system font."""
    # Try cached TikTok Sans first
    target = TIKTOK_SANS_BOLD if weight == "bold" else TIKTOK_SANS_REGULAR
    if os.path.exists(target):
        return target

    # Try downloading
    if download_tiktok_sans() and os.path.exists(target):
        return target

    # Fallback
    for fp in FALLBACK_FONTS:
        if os.path.exists(fp):
            print(f"Warning: using fallback font {os.path.basename(fp)}", file=sys.stderr)
            return fp

    return None


# ─────────────────────────────────────────────
# Presets
# ─────────────────────────────────────────────

PRESETS = {
    "tiktok-wall": {
        "font_weight": "regular",
        "size": 38,
        "fill": (247, 247, 242, 240),         # muted warm white, 94% opacity
        "stroke_color": (0, 0, 0, 255),        # pure black
        "stroke_width": 3,                      # nearest int to 2.5px (PIL uses int)
        "align": "center",
        "y_start": 280,                         # safe zone
        "line_height": 50,
    },
    "tiktok-hook": {
        "font_weight": "bold",
        "size": 52,
        "fill": (255, 255, 255, 255),           # bright white
        "stroke_color": (0, 0, 0, 255),
        "stroke_width": 3,
        "align": "center",
        "y_start": 320,
        "line_height": 66,
    },
    "tiktok-scene": {
        "font_weight": "regular",
        "size": 32,
        "fill": (247, 247, 242, 240),
        "stroke_color": (0, 0, 0, 255),
        "stroke_width": 2,
        "align": "center",
        "y_start": 280,
        "line_height": 44,
    },
    "tiktok-dense": {
        "font_weight": "regular",
        "size": 28,
        "fill": (247, 247, 242, 240),
        "stroke_color": (0, 0, 0, 255),
        "stroke_width": 2,
        "align": "center",
        "y_start": 240,
        "line_height": 36,
    },
}


# ─────────────────────────────────────────────
# Video resolution detection
# ─────────────────────────────────────────────

def get_video_resolution(video_path):
    """Get video width and height using ffprobe."""
    for ffprobe in ["/usr/bin/ffprobe", "ffprobe"]:
        try:
            result = subprocess.run(
                [ffprobe, "-v", "quiet", "-select_streams", "v:0",
                 "-show_entries", "stream=width,height", "-of", "json",
                 video_path],
                capture_output=True, text=True, timeout=10,
            )
            data = json.loads(result.stdout)
            stream = data["streams"][0]
            return int(stream["width"]), int(stream["height"])
        except (FileNotFoundError, KeyError, json.JSONDecodeError, IndexError):
            continue
    return None, None


# ─────────────────────────────────────────────
# Caption generation
# ─────────────────────────────────────────────

def generate_caption(config):
    """Generate a transparent PNG caption overlay from a config dict."""
    width = config.get("width", 720)
    height = config.get("height", 1280)
    lines = config.get("lines", [])
    size = config.get("size", 38)
    fill = tuple(config.get("fill", (247, 247, 242, 240)))
    stroke_color = tuple(config.get("stroke_color", (0, 0, 0, 255)))
    stroke_width = int(config.get("stroke_width", 3))
    align = config.get("align", "center")
    y_start = config.get("y_start", 280)
    line_height = config.get("line_height", 50)
    font_weight = config.get("font_weight", "regular")
    output_path = config.get("output", "caption.png")

    # Scale values if resolution differs from 720x1280 base
    scale = width / 720
    scaled_size = int(size * scale)
    scaled_y = int(y_start * scale)
    scaled_lh = int(line_height * scale)
    scaled_stroke = max(1, int(stroke_width * scale))

    # Find font
    font_path = find_font(font_weight)
    if font_path is None:
        print("Error: no suitable font found", file=sys.stderr)
        sys.exit(2)

    font = ImageFont.truetype(font_path, scaled_size)

    # Create transparent image
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for i, line in enumerate(lines):
        y = scaled_y + i * scaled_lh

        if align == "center":
            bbox = draw.textbbox((0, 0), line, font=font)
            tw = bbox[2] - bbox[0]
            x = (width - tw) // 2
        elif align == "left":
            x = int(40 * scale)  # left margin
        else:
            bbox = draw.textbbox((0, 0), line, font=font)
            tw = bbox[2] - bbox[0]
            x = width - tw - int(40 * scale)

        # Draw text with stroke
        draw.text(
            (x, y), line, font=font, fill=fill,
            stroke_width=scaled_stroke, stroke_fill=stroke_color,
        )

    img.save(output_path)
    file_size = os.path.getsize(output_path)
    print(f"Saved {output_path} ({width}x{height}, {file_size} bytes)")
    return output_path


# ─────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description="Generate TikTok-native text overlay PNG",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Presets:
  tiktok-wall   TikTok Sans Regular 38px, muted white, 2.5px stroke (default)
  tiktok-hook   TikTok Sans Bold 52px, bright white, 3px stroke
  tiktok-scene  TikTok Sans Regular 32px, muted white, 2px stroke
  tiktok-dense  TikTok Sans Regular 28px, muted white, tight spacing""",
    )
    ap.add_argument("--lines", help="Comma-separated caption lines")
    ap.add_argument("--config", help="JSON config file (overrides other args)")
    ap.add_argument("--output", "-o", default="caption.png", help="Output PNG path")
    ap.add_argument("--preset", choices=list(PRESETS.keys()), default="tiktok-wall",
                    help="Style preset (default: tiktok-wall)")
    ap.add_argument("--video", help="Input video for auto-detecting resolution")
    ap.add_argument("--width", type=int, default=None)
    ap.add_argument("--height", type=int, default=None)
    ap.add_argument("--size", type=int, default=None, help="Font size in px")
    ap.add_argument("--y-start", type=int, default=None, help="Y position of first line")
    ap.add_argument("--line-height", type=int, default=None, help="Line height in px")
    ap.add_argument("--stroke-width", type=float, default=None, help="Stroke width in px")
    ap.add_argument("--fill", help="Fill color as R,G,B,A (e.g. 247,247,242,240)")
    ap.add_argument("--stroke-color", help="Stroke color as R,G,B,A (e.g. 0,0,0,255)")
    ap.add_argument("--font-weight", choices=["regular", "bold"], default=None)
    ap.add_argument("--align", choices=["left", "center", "right"], default=None)
    ap.add_argument("--list-presets", action="store_true", help="Show all presets and exit")
    args = ap.parse_args()

    # List presets
    if args.list_presets:
        for name, p in PRESETS.items():
            print(f"\n{name}:")
            for k, v in p.items():
                print(f"  {k}: {v}")
        return

    # Load config from JSON file or build from preset + CLI overrides
    if args.config:
        with open(args.config) as f:
            config = json.load(f)
    else:
        if not args.lines:
            ap.error("--lines or --config is required")
        config = dict(PRESETS[args.preset])
        config["lines"] = [l.strip() for l in args.lines.split(",") if l.strip()]

    # Resolution: video auto-detect > CLI args > config > default 720x1280
    width = args.width
    height = args.height
    if args.video and (width is None or height is None):
        vw, vh = get_video_resolution(args.video)
        if vw and vh:
            width = width or vw
            height = height or vh
            print(f"Detected video resolution: {width}x{height}")
        else:
            print("Warning: could not detect video resolution, using defaults")
    config["width"] = width or config.get("width", 720)
    config["height"] = height or config.get("height", 1280)

    # CLI overrides
    if args.size is not None:
        config["size"] = args.size
    if args.y_start is not None:
        config["y_start"] = args.y_start
    if args.line_height is not None:
        config["line_height"] = args.line_height
    if args.stroke_width is not None:
        config["stroke_width"] = args.stroke_width
    if args.fill:
        config["fill"] = tuple(int(x) for x in args.fill.split(","))
    if args.stroke_color:
        config["stroke_color"] = tuple(int(x) for x in args.stroke_color.split(","))
    if args.font_weight:
        config["font_weight"] = args.font_weight
    if args.align:
        config["align"] = args.align

    config["output"] = args.output

    generate_caption(config)


if __name__ == "__main__":
    main()
