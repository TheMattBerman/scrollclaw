#!/usr/bin/env bash
# check-deps.sh — Dependency checker for ScrollClaw
# Run before your first video: bash scripts/check-deps.sh
# Exit 0 = all required deps pass. Exit 1 = something required is missing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS="✅"
FAIL="❌"
WARN="⚠️ "
INFO="ℹ️ "

REQUIRED_FAILURES=0

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

pass()  { echo "  ${PASS} $1"; }
fail()  { echo "  ${FAIL} $1"; REQUIRED_FAILURES=$((REQUIRED_FAILURES + 1)); }
warn()  { echo "  ${WARN} $1"; }
info()  { echo "  ${INFO} $1"; }
header(){ echo; echo "━━━ $1 ━━━"; }

# ─────────────────────────────────────────────
# 1. Required environment variables
# ─────────────────────────────────────────────

header "Required API Keys"

if [[ -n "${FAL_KEY:-}" ]]; then
  pass "FAL_KEY is set"
else
  fail "FAL_KEY is missing"
  echo "       → Get your key at: https://fal.ai/dashboard/keys"
  echo "       → Add to ~/.bashrc: export FAL_KEY=\"your-key\""
  echo "       → Then run: source ~/.bashrc"
fi

if [[ -n "${REPLICATE_API_TOKEN:-}" ]]; then
  pass "REPLICATE_API_TOKEN is set"
else
  fail "REPLICATE_API_TOKEN is missing"
  echo "       → Get your token at: https://replicate.com/account/api-tokens"
  echo "       → Add to ~/.bashrc: export REPLICATE_API_TOKEN=\"r8_your-token\""
  echo "       → Then run: source ~/.bashrc"
fi

# ─────────────────────────────────────────────
# 2. Optional environment variables
# ─────────────────────────────────────────────

header "Optional API Keys"

if [[ -n "${ELEVENLABS_API_KEY:-}" ]]; then
  pass "ELEVENLABS_API_KEY is set (multi-clip voice consistency enabled)"
else
  warn "ELEVENLABS_API_KEY is not set"
  info "Required for multi-clip videos with consistent voice (S2S)."
  info "Single-clip talking head works without it (uses Sora's built-in audio)."
  echo "       → Get your key at: https://elevenlabs.io/app/settings/api-keys"
  echo "       → Add to ~/.bashrc: export ELEVENLABS_API_KEY=\"your-key\""
fi

# ─────────────────────────────────────────────
# 3. ffmpeg (system apt version, NOT Homebrew)
# ─────────────────────────────────────────────

header "ffmpeg"

FFMPEG_PATH="/usr/bin/ffmpeg"

if [[ -x "$FFMPEG_PATH" ]]; then
  pass "ffmpeg found at $FFMPEG_PATH"
else
  fail "ffmpeg not found at $FFMPEG_PATH"
  echo "       → Install with: sudo apt update && sudo apt install ffmpeg"
  echo "       → Must be the apt version (not Homebrew) for drawtext/libass support."

  # Check if a homebrew version is around anyway, just for the warning
  if command -v ffmpeg &>/dev/null; then
    HOMEBREW_FFMPEG=$(command -v ffmpeg)
    if [[ "$HOMEBREW_FFMPEG" != "$FFMPEG_PATH" ]]; then
      warn "Found ffmpeg at $HOMEBREW_FFMPEG — but that version likely lacks libfreetype/libass."
      info "Caption generation requires /usr/bin/ffmpeg (apt). Install the apt version."
    fi
  fi
fi

# Check drawtext filter (needs libfreetype)
if [[ -x "$FFMPEG_PATH" ]]; then
  if "$FFMPEG_PATH" -filters 2>/dev/null | grep -q "drawtext"; then
    pass "ffmpeg has drawtext filter (libfreetype enabled)"
  else
    fail "ffmpeg is missing drawtext filter (libfreetype not compiled in)"
    echo "       → Install the full apt version: sudo apt install ffmpeg"
    echo "       → The apt package includes libfreetype support."
    echo "       → Verify after install: /usr/bin/ffmpeg -filters 2>/dev/null | grep drawtext"
  fi
fi

# ─────────────────────────────────────────────
# 4. ffprobe
# ─────────────────────────────────────────────

header "ffprobe"

FFPROBE_PATH="/usr/bin/ffprobe"

if [[ -x "$FFPROBE_PATH" ]]; then
  pass "ffprobe found at $FFPROBE_PATH"
elif command -v ffprobe &>/dev/null; then
  warn "ffprobe found at $(command -v ffprobe) (not /usr/bin/ffprobe)"
  info "Caption resolution auto-detection uses /usr/bin/ffprobe. Install apt ffmpeg."
  echo "       → sudo apt install ffmpeg"
else
  fail "ffprobe not found"
  echo "       → Install with: sudo apt install ffmpeg (ffprobe ships with it)"
fi

# ─────────────────────────────────────────────
# 5. Python3 + PIL (system Python, NOT Homebrew)
# ─────────────────────────────────────────────

header "Python3 + PIL"

PYTHON_PATH="/usr/bin/python3"

if [[ -x "$PYTHON_PATH" ]]; then
  pass "python3 found at $PYTHON_PATH"

  if "$PYTHON_PATH" -c "from PIL import Image" 2>/dev/null; then
    PIL_VER=$("$PYTHON_PATH" -c "from PIL import __version__; print(__version__)" 2>/dev/null || echo "unknown")
    pass "PIL (Pillow) available via $PYTHON_PATH (version: $PIL_VER)"
  else
    fail "PIL not available via $PYTHON_PATH"
    echo "       → Install with: sudo apt install python3-pil"
    echo "       → Or via pip: sudo pip3 install Pillow"
    echo "       → Must be importable by /usr/bin/python3 specifically."
    echo "       → Homebrew Python in a different PATH won't work for caption generation."
  fi
else
  fail "python3 not found at $PYTHON_PATH"
  echo "       → Install with: sudo apt install python3"

  if command -v python3 &>/dev/null; then
    ALT_PYTHON=$(command -v python3)
    warn "Found python3 at $ALT_PYTHON — but scripts use /usr/bin/python3 explicitly."
    info "Install the apt version alongside Homebrew: sudo apt install python3"
  fi
fi

# ─────────────────────────────────────────────
# 6. Inter SemiBold font (auto-download if missing)
# ─────────────────────────────────────────────

header "Inter SemiBold Font"

FONT_PATH="/tmp/fonts/extras/ttf/Inter-SemiBold.ttf"
INTER_RELEASE_URL="https://github.com/rsms/inter/releases/download/v3.19/Inter-3.19.zip"
INTER_ZIP="/tmp/inter-check-deps.zip"

if [[ -f "$FONT_PATH" ]]; then
  pass "Inter SemiBold found at $FONT_PATH"
else
  warn "Inter SemiBold not found at $FONT_PATH"
  echo "       → Attempting auto-download from GitHub releases..."
  echo

  FONT_DIR=$(dirname "$FONT_PATH")
  mkdir -p "$FONT_DIR"

  if command -v curl &>/dev/null; then
    if curl -fsSL "$INTER_RELEASE_URL" -o "$INTER_ZIP" 2>/dev/null; then
      echo "       Downloaded Inter-3.19.zip"

      if command -v unzip &>/dev/null; then
        if unzip -j -o "$INTER_ZIP" "Inter Desktop/Inter-SemiBold.ttf" -d "$FONT_DIR" &>/dev/null; then
          rm -f "$INTER_ZIP"
          if [[ -f "$FONT_PATH" ]]; then
            pass "Inter SemiBold downloaded and installed at $FONT_PATH"
          else
            # Try alternate path inside zip (zip structure may differ)
            if unzip -j -o "$INTER_ZIP" "*Inter-SemiBold.ttf" -d "$FONT_DIR" &>/dev/null 2>&1; then
              rm -f "$INTER_ZIP"
              pass "Inter SemiBold downloaded and installed at $FONT_PATH"
            else
              rm -f "$INTER_ZIP"
              fail "Downloaded Inter zip but could not extract Inter-SemiBold.ttf"
              echo "       → Manual install:"
              echo "         mkdir -p /tmp/fonts/extras/ttf"
              echo "         curl -L '$INTER_RELEASE_URL' -o /tmp/inter.zip"
              echo "         unzip -j /tmp/inter.zip '*Inter-SemiBold.ttf' -d /tmp/fonts/extras/ttf/"
            fi
          fi
        else
          # Extraction failed — try wildcard
          if unzip -j -o "$INTER_ZIP" "*Inter-SemiBold.ttf" -d "$FONT_DIR" &>/dev/null; then
            rm -f "$INTER_ZIP"
            if [[ -f "$FONT_PATH" ]]; then
              pass "Inter SemiBold downloaded and installed at $FONT_PATH"
            else
              rm -f "$INTER_ZIP"
              fail "Font file not at expected path after extraction"
              echo "       → Check: ls $FONT_DIR"
              echo "       → Expected: $FONT_PATH"
            fi
          else
            rm -f "$INTER_ZIP"
            fail "Could not extract Inter SemiBold from zip"
            echo "       → Manual install:"
            echo "         mkdir -p /tmp/fonts/extras/ttf"
            echo "         curl -L '$INTER_RELEASE_URL' -o /tmp/inter.zip"
            echo "         unzip -j /tmp/inter.zip '*Inter-SemiBold.ttf' -d /tmp/fonts/extras/ttf/"
          fi
        fi
      else
        rm -f "$INTER_ZIP"
        fail "unzip not available — cannot extract font"
        echo "       → Install unzip: sudo apt install unzip"
        echo "       → Then re-run this script."
      fi
    else
      fail "Could not download Inter from GitHub (check network/curl)"
      echo "       → Manual install:"
      echo "         mkdir -p /tmp/fonts/extras/ttf"
      echo "         curl -L '$INTER_RELEASE_URL' -o /tmp/inter.zip"
      echo "         unzip -j /tmp/inter.zip 'Inter Desktop/Inter-SemiBold.ttf' -d /tmp/fonts/extras/ttf/"
    fi
  else
    fail "curl not available — cannot auto-download font"
    echo "       → Install curl: sudo apt install curl"
    echo "       → Then re-run this script."
  fi
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$REQUIRED_FAILURES" -eq 0 ]]; then
  echo "  ✅  All required dependencies passed. You're ready to generate UGC."
  echo
  echo "  Next step: Ask Claude to create a UGC video campaign."
  echo "  Full docs: $REPO_ROOT/SKILL.md"
  exit 0
else
  echo "  ❌  $REQUIRED_FAILURES required dependency check(s) failed."
  echo
  echo "  Fix the issues above and re-run: bash scripts/check-deps.sh"
  echo "  Full docs: $REPO_ROOT/README.md"
  exit 1
fi
