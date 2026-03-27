#!/usr/bin/env bash
# pre-flight.sh — Pre-production checklist for ScrollClaw campaigns
# Run BEFORE generating anything: bash scripts/pre-flight.sh <campaign-slug>
# Exit 0 = ready to produce. Exit 1 = missing prerequisites.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS="✅"
FAIL="❌"
WARN="⚠️ "
INFO="ℹ️ "

FAILURES=0
WARNINGS=0

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

pass()  { echo "  ${PASS} $1"; }
fail()  { echo "  ${FAIL} $1"; FAILURES=$((FAILURES + 1)); }
warn()  { echo "  ${WARN} $1"; WARNINGS=$((WARNINGS + 1)); }
info()  { echo "  ${INFO} $1"; }
header(){ echo; echo "━━━ $1 ━━━"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <campaign-slug>

Pre-production checklist — validates everything needed before generation.

Arguments:
  campaign-slug   The campaign directory name under workspace/campaigns/

Options:
  -h, --help      Show this help message

Example:
  bash scripts/pre-flight.sh ridge-wallet
EOF
  exit 0
}

# ─────────────────────────────────────────────
# Args
# ─────────────────────────────────────────────

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
  usage
fi

SLUG="${1:-}"
if [[ -z "$SLUG" ]]; then
  echo "Error: campaign slug required"
  echo "Usage: $(basename "$0") <campaign-slug>"
  exit 1
fi

CAMPAIGN_DIR="$REPO_ROOT/workspace/campaigns/$SLUG"

echo "🎬 ScrollClaw Pre-Flight Check"
echo "   Campaign: $SLUG"
echo "   Path: $CAMPAIGN_DIR"

# ─────────────────────────────────────────────
# 1. Campaign workspace structure
# ─────────────────────────────────────────────

header "Campaign Workspace"

if [[ -d "$CAMPAIGN_DIR" ]]; then
  pass "Campaign directory exists"
else
  fail "Campaign directory not found: $CAMPAIGN_DIR"
  echo
  echo "Create it with:"
  echo "  mkdir -p workspace/campaigns/$SLUG/{creators,scripts,frames,clips,scores}"
  echo "  cp assets/campaign-brief-template.md workspace/campaigns/$SLUG/brief.md"
  exit 1
fi

for dir in creators scripts frames clips scores; do
  if [[ -d "$CAMPAIGN_DIR/$dir" ]]; then
    pass "  $dir/ exists"
  else
    fail "  $dir/ missing"
  fi
done

if [[ -f "$CAMPAIGN_DIR/brief.md" ]]; then
  pass "Campaign brief exists"
else
  warn "No brief.md — recommended for persona research"
fi

if [[ -f "$CAMPAIGN_DIR/output-log.md" ]]; then
  pass "Output log exists"
else
  warn "No output-log.md — create with: touch workspace/campaigns/$SLUG/output-log.md"
fi

# ─────────────────────────────────────────────
# 2. Brand context (warn-only — not required)
# ─────────────────────────────────────────────

header "Brand Context"

BRAND_DIR="$REPO_ROOT/workspace/brand"
BRAND_FILES=("voice-profile.md" "positioning.md" "audience.md")
BRAND_FOUND=0

for bf in "${BRAND_FILES[@]}"; do
  if [[ -f "$BRAND_DIR/$bf" ]]; then
    pass "$bf"
    BRAND_FOUND=$((BRAND_FOUND + 1))
  else
    warn "$bf not found — persona research will infer from campaign brief only"
  fi
done

if [[ $BRAND_FOUND -eq 0 ]]; then
  info "No brand files found. Run /brand-setup with your brand name + URL (recommended),"
  info "or copy templates manually:"
  info "  mkdir -p workspace/brand"
  info "  cp assets/voice-profile-template.md workspace/brand/voice-profile.md"
  info "  cp assets/positioning-template.md workspace/brand/positioning.md"
  info "  cp assets/audience-template.md workspace/brand/audience.md"
fi

# ─────────────────────────────────────────────
# 3. Creator profile
# ─────────────────────────────────────────────

header "Creator Profile"

CREATOR_FILES=()
# Check campaign-specific creators first
if compgen -G "$CAMPAIGN_DIR/creators/creator-*.md" > /dev/null 2>&1; then
  while IFS= read -r f; do
    CREATOR_FILES+=("$f")
  done < <(find "$CAMPAIGN_DIR/creators" -name "creator-*.md" -type f 2>/dev/null)
fi
# Check global creators
if compgen -G "$REPO_ROOT/workspace/creators/creator-*.md" > /dev/null 2>&1; then
  while IFS= read -r f; do
    CREATOR_FILES+=("$f")
  done < <(find "$REPO_ROOT/workspace/creators" -name "creator-*.md" -type f 2>/dev/null)
fi

if [[ ${#CREATOR_FILES[@]} -gt 0 ]]; then
  pass "Creator profile(s) found:"
  for f in "${CREATOR_FILES[@]}"; do
    info "  $(basename "$f")"
  done
else
  fail "No creator profiles found (creator-*.md)"
  echo "     Check: workspace/campaigns/$SLUG/creators/ or workspace/creators/"
fi

# ─────────────────────────────────────────────
# 4. Reference image for i2v
# ─────────────────────────────────────────────

header "Reference Image"

REF_IMAGES=()
if compgen -G "$CAMPAIGN_DIR/frames/*-reference.*" > /dev/null 2>&1; then
  while IFS= read -r f; do
    REF_IMAGES+=("$f")
  done < <(find "$CAMPAIGN_DIR/frames" -name "*-reference.*" -type f 2>/dev/null)
fi
# Also check for first-frame images
if compgen -G "$CAMPAIGN_DIR/frames/first-frame-*" > /dev/null 2>&1; then
  while IFS= read -r f; do
    REF_IMAGES+=("$f")
  done < <(find "$CAMPAIGN_DIR/frames" -name "first-frame-*" -type f 2>/dev/null)
fi

if [[ ${#REF_IMAGES[@]} -gt 0 ]]; then
  pass "Reference image(s) found:"
  for f in "${REF_IMAGES[@]}"; do
    info "  $(basename "$f")"
  done
else
  fail "No reference images found in frames/"
  echo "     Expected: frames/*-reference.jpg or frames/first-frame-*"
  echo "     ⚠️  NEVER generate random people — always use creator reference image"
fi

# ─────────────────────────────────────────────
# 5. Script with segment mapping
# ─────────────────────────────────────────────

header "Script"

SCRIPT_FILES=()
if compgen -G "$CAMPAIGN_DIR/scripts/*-script.md" > /dev/null 2>&1; then
  while IFS= read -r f; do
    SCRIPT_FILES+=("$f")
  done < <(find "$CAMPAIGN_DIR/scripts" -name "*-script.md" -type f 2>/dev/null)
fi
# Also check for any .md in scripts/
if [[ ${#SCRIPT_FILES[@]} -eq 0 ]] && compgen -G "$CAMPAIGN_DIR/scripts/*.md" > /dev/null 2>&1; then
  while IFS= read -r f; do
    SCRIPT_FILES+=("$f")
  done < <(find "$CAMPAIGN_DIR/scripts" -name "*.md" -type f 2>/dev/null)
fi

if [[ ${#SCRIPT_FILES[@]} -gt 0 ]]; then
  pass "Script file(s) found:"
  for f in "${SCRIPT_FILES[@]}"; do
    info "  $(basename "$f")"
    # Check for segment/scene markers
    if grep -qiE '(scene|segment|s[0-9]|clip [0-9])' "$f" 2>/dev/null; then
      pass "  Has segment mapping"
    else
      warn "  No segment/scene markers found — add scene-by-scene breakdown"
    fi
  done
else
  fail "No script files found in scripts/"
fi

# ─────────────────────────────────────────────
# 6. Caption plan
# ─────────────────────────────────────────────

header "Caption Plan"

HAS_CAPTION_PLAN=false
for f in "${SCRIPT_FILES[@]}"; do
  if grep -qiE '(caption|text overlay|on-screen text)' "$f" 2>/dev/null; then
    HAS_CAPTION_PLAN=true
    pass "Caption references found in $(basename "$f")"
  fi
done

# Check for dedicated caption config
if compgen -G "$CAMPAIGN_DIR/scripts/*caption*" > /dev/null 2>&1; then
  HAS_CAPTION_PLAN=true
  pass "Dedicated caption config found"
fi
if compgen -G "$CAMPAIGN_DIR/scripts/*overlay*" > /dev/null 2>&1; then
  HAS_CAPTION_PLAN=true
  pass "Dedicated overlay config found"
fi

if [[ "$HAS_CAPTION_PLAN" == "false" ]]; then
  warn "No caption plan detected"
  echo "     Define text + timing for EVERY scene before generating"
fi

# ─────────────────────────────────────────────
# 7. Text style parameters
# ─────────────────────────────────────────────

header "Text Style"

HAS_STYLE=false
for f in "${SCRIPT_FILES[@]}"; do
  if grep -qiE '(font|stroke|tiktok sans|fill.*(color|#))' "$f" 2>/dev/null; then
    HAS_STYLE=true
    pass "Text style parameters found in $(basename "$f")"
  fi
done

if [[ "$HAS_STYLE" == "false" ]]; then
  warn "No text style parameters set"
  info "Default: TikTok Sans Regular 38px, #F7F7F2 94% opacity, 2.5px black stroke"
  info "Set in script or use caption-overlay.py presets"
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $FAILURES -eq 0 ]]; then
  echo "  ✅ PRE-FLIGHT PASSED ($WARNINGS warning(s))"
  echo "  Ready to produce. Follow production-pipeline.md order."
else
  echo "  ❌ PRE-FLIGHT FAILED — $FAILURES issue(s), $WARNINGS warning(s)"
  echo "  Fix failures above before generating anything."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $((FAILURES > 0 ? 1 : 0))
