#!/usr/bin/env python3
"""Generate native-style caption overlay PNG for UGC videos.

Two styles:
  --style pill    White pill backgrounds per line (Hook Face + Demo, Talking Head)
  --style wall    Raw white text with drop shadow, no background (Wall of Text)

Auto-detects video resolution if --video is provided.

Usage:
    # Pill style (default) — for hooks and talking heads
    python3 generate-caption.py \
        --video hook.mp4 \
        --lines "when your gym software,cannot even handle,a data migration..." \
        --output caption.png

    # Wall of text style — dense white text, no background
    python3 generate-caption.py \
        --video wall.mp4 --style wall \
        --lines "my favorite hobby is paying off,my credit card. i pay my credit,card bill AT LEAST once a,week. you will NOT catch me in,credit card debt. slow at work?,might as well pay off my credit,card. day off? guess i'll pay my,credit card." \
        --output wall-caption.png

    # Overlay with ffmpeg:
    ffmpeg -i video.mp4 -i caption.png \
        -filter_complex "[0:v][1:v]overlay=0:0:enable='between(t,0.2,3.8)'" \
        -c:v libx264 -preset fast -crf 18 -c:a copy output.mp4
"""
import argparse
import json
import os
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont


# Font paths
DEFAULT_FONT = "/tmp/fonts/extras/ttf/Inter-SemiBold.ttf"
BOLD_FONT = "/tmp/fonts/extras/ttf/Inter-Bold.ttf"
FALLBACK_FONTS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
]

# Scale base
BASE_WIDTH = 720


def get_video_resolution(video_path):
    """Get video width and height using ffprobe."""
    for ffprobe in ["/usr/bin/ffprobe", "ffprobe"]:
        try:
            result = subprocess.run(
                [ffprobe, "-v", "quiet", "-select_streams", "v:0",
                 "-show_entries", "stream=width,height", "-of", "json",
                 video_path],
                capture_output=True, text=True, timeout=10
            )
            data = json.loads(result.stdout)
            stream = data["streams"][0]
            return int(stream["width"]), int(stream["height"])
        except (FileNotFoundError, KeyError, json.JSONDecodeError, IndexError):
            continue
    return None, None


def find_font(preferred=DEFAULT_FONT):
    """Find a usable font file."""
    if os.path.exists(preferred):
        return preferred
    for fp in FALLBACK_FONTS:
        if os.path.exists(fp):
            return fp
    return None


def generate_pill_caption(width, height, lines, font_size=None, y_position=None,
                          output_path="caption.png"):
    """Pill style: white rounded rectangles behind each line. For hooks and talking heads."""
    scale = width / BASE_WIDTH

    if font_size is None:
        font_size = int(47 * scale)
    pad_h = int(24 * scale)
    pad_v = int(16 * scale)
    radius = int(15 * scale)
    if y_position is None:
        y_position = int(height * 0.145)

    font_path = find_font()
    if font_path is None:
        print("Error: no suitable font found", file=sys.stderr)
        sys.exit(2)

    font = ImageFont.truetype(font_path, font_size)
    ascent, descent = font.getmetrics()

    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pill_specs = []
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        tw = bbox[2] - bbox[0]
        pill_w = tw + pad_h * 2
        pill_h = ascent + descent + pad_v * 2
        pill_specs.append((line, tw, pill_w, pill_h))

    max_pill_h = max(s[3] for s in pill_specs)

    for i, (line, tw, pill_w, pill_h) in enumerate(pill_specs):
        pill_x = (width - pill_w) // 2
        pill_y = y_position + i * max_pill_h

        # Shadow
        draw.rounded_rectangle(
            [pill_x + 1, pill_y + 2, pill_x + pill_w + 1, pill_y + max_pill_h + 2],
            radius=radius, fill=(0, 0, 0, 18)
        )
        # White pill
        draw.rounded_rectangle(
            [pill_x, pill_y, pill_x + pill_w, pill_y + max_pill_h],
            radius=radius, fill=(255, 255, 255, 255)
        )
        # Text
        tx = (width - tw) // 2
        ty = pill_y + pad_v
        draw.text((tx, ty), line, font=font, fill=(10, 25, 49, 255))

    img.save(output_path)
    print(f"Saved {output_path} ({width}x{height}, {os.path.getsize(output_path)} bytes)")


def generate_wall_caption(width, height, lines, font_size=None, y_position=None,
                          output_path="caption.png"):
    """Wall of text style: bold white text with drop shadow, no background.
    Dense, centered, fills upper 40-60% of frame. TikTok native text look."""
    scale = width / BASE_WIDTH

    if font_size is None:
        font_size = int(38 * scale)  # slightly smaller for dense text
    line_spacing = int(6 * scale)
    if y_position is None:
        y_position = int(height * 0.08)  # higher on frame for wall of text

    # Prefer bold for wall of text
    font_path = find_font(BOLD_FONT)
    if font_path is None:
        font_path = find_font()
    if font_path is None:
        print("Error: no suitable font found", file=sys.stderr)
        sys.exit(2)

    font = ImageFont.truetype(font_path, font_size)
    ascent, descent = font.getmetrics()
    line_h = ascent + descent

    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for i, line in enumerate(lines):
        bbox = draw.textbbox((0, 0), line, font=font)
        tw = bbox[2] - bbox[0]
        tx = (width - tw) // 2
        ty = y_position + i * (line_h + line_spacing)

        # Drop shadow (offset 2px down-right, semi-transparent black)
        draw.text((tx + 2, ty + 2), line, font=font, fill=(0, 0, 0, 120))
        # White text
        draw.text((tx, ty), line, font=font, fill=(255, 255, 255, 255))

    img.save(output_path)
    print(f"Saved {output_path} ({width}x{height}, {os.path.getsize(output_path)} bytes)")


def main():
    ap = argparse.ArgumentParser(description="Generate caption overlay PNG")
    ap.add_argument("--lines", required=True,
                    help="Comma-separated caption lines")
    ap.add_argument("--output", required=True,
                    help="Output PNG path")
    ap.add_argument("--style", choices=["pill", "wall"], default="pill",
                    help="Caption style: pill (white boxes) or wall (raw text, no bg)")
    ap.add_argument("--video",
                    help="Input video (auto-detect resolution)")
    ap.add_argument("--width", type=int, default=None)
    ap.add_argument("--height", type=int, default=None)
    ap.add_argument("--font-size", type=int, default=None)
    ap.add_argument("--y-position", type=int, default=None)
    args = ap.parse_args()

    width = args.width
    height = args.height

    if args.video and (width is None or height is None):
        vw, vh = get_video_resolution(args.video)
        if vw and vh:
            width = width or vw
            height = height or vh
            print(f"Detected video resolution: {width}x{height}")
        else:
            print("Warning: could not detect video resolution, using 720x1280")
            width = width or 720
            height = height or 1280
    else:
        width = width or 720
        height = height or 1280

    lines = [l.strip() for l in args.lines.split(",") if l.strip()]

    if args.style == "wall":
        generate_wall_caption(
            width=width, height=height, lines=lines,
            font_size=args.font_size, y_position=args.y_position,
            output_path=args.output,
        )
    else:
        generate_pill_caption(
            width=width, height=height, lines=lines,
            font_size=args.font_size, y_position=args.y_position,
            output_path=args.output,
        )


if __name__ == "__main__":
    main()
