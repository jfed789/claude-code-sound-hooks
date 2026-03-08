#!/usr/bin/env bash
# =============================================================================
# Claude Code Sound Hooks — Installer
# Creates directory structure, installs play.sh + theme config, shows hook setup.
#
# Usage:
#   ./install.sh                  # install with default theme (masterchief)
#   ./install.sh <theme-name>     # install with a specific theme
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME="${1:-masterchief}"
THEME_DIR="$REPO_DIR/themes/$THEME"
INSTALL_DIR="$HOME/.claude/sounds/$THEME"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo "  $1"; }
step()  { echo ""; echo "[$1/$TOTAL] $2"; }
ok()    { echo "  -> done"; }

# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------
if [[ ! -d "$THEME_DIR" ]]; then
  echo "Error: Theme '$THEME' not found at $THEME_DIR"
  echo ""
  echo "Available themes:"
  for d in "$REPO_DIR"/themes/*/; do
    [[ -d "$d" ]] && echo "  - $(basename "$d")"
  done
  exit 1
fi

if [[ ! -f "$THEME_DIR/config.sh" ]]; then
  echo "Error: Theme '$THEME' is missing config.sh"
  exit 1
fi

TOTAL=4

echo "========================================"
echo " Claude Code Sound Hooks — Installer"
echo " Theme: $THEME"
echo "========================================"

# ---------------------------------------------------------------------------
# Step 1: Create directory structure
# ---------------------------------------------------------------------------
step 1 "Creating sound directory structure..."

dirs=(
  "$INSTALL_DIR/session_start"
  "$INSTALL_DIR/prompt_submit"
  "$INSTALL_DIR/needs_input"
  "$INSTALL_DIR/task_complete"
  "$INSTALL_DIR/error/instant"
  "$INSTALL_DIR/error/quiet"
  "$INSTALL_DIR/error/violent"
  "$INSTALL_DIR/working"
  "$INSTALL_DIR/flavor"
)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
  info "Created $d"
done
ok

# ---------------------------------------------------------------------------
# Step 2: Install playback engine
# ---------------------------------------------------------------------------
step 2 "Installing play.sh..."

cp "$REPO_DIR/play.sh" "$INSTALL_DIR/play.sh"
chmod +x "$INSTALL_DIR/play.sh"
info "Installed $INSTALL_DIR/play.sh"
ok

# ---------------------------------------------------------------------------
# Step 3: Install theme config
# ---------------------------------------------------------------------------
step 3 "Installing theme config..."

cp "$THEME_DIR/config.sh" "$INSTALL_DIR/config.sh"
info "Installed $INSTALL_DIR/config.sh"
ok

# ---------------------------------------------------------------------------
# Step 4: Hook configuration
# ---------------------------------------------------------------------------
step 4 "Configuring Claude Code hooks..."

SETTINGS_FILE="$HOME/.claude/settings.json"
HOOKS_FILE="$REPO_DIR/hooks.json"

# Update the hooks.json paths for the chosen theme
HOOKS_CONTENT=$(sed "s|masterchief|$THEME|g" "$HOOKS_FILE")

if [[ -f "$SETTINGS_FILE" ]]; then
  # Check if jq is available for safe merge
  if command -v jq &>/dev/null; then
    # Check if hooks already exist
    existing_hooks=$(jq -r '.hooks // empty' "$SETTINGS_FILE" 2>/dev/null)

    if [[ -n "$existing_hooks" && "$existing_hooks" != "null" ]]; then
      echo ""
      info "You already have hooks in $SETTINGS_FILE."
      info "To avoid overwriting your existing hooks, please merge manually."
      echo ""
      info "Add the following to the \"hooks\" section of $SETTINGS_FILE:"
      echo ""
      echo "$HOOKS_CONTENT" | jq '.' 2>/dev/null || echo "$HOOKS_CONTENT"
      echo ""
      info "Or replace the entire hooks section by running:"
      info "  jq '.hooks = input' $SETTINGS_FILE <(echo '$HOOKS_CONTENT') > /tmp/settings.json && mv /tmp/settings.json $SETTINGS_FILE"
    else
      # No existing hooks — safe to add
      jq --argjson hooks "$HOOKS_CONTENT" '.hooks = $hooks' "$SETTINGS_FILE" > /tmp/claude_settings_tmp.json
      mv /tmp/claude_settings_tmp.json "$SETTINGS_FILE"
      info "Added hooks to $SETTINGS_FILE"
    fi
  else
    echo ""
    info "jq not found — showing hooks config for manual setup."
    info "Install jq (brew install jq) and re-run for auto-config."
    echo ""
    info "Add a \"hooks\" key to $SETTINGS_FILE with this content:"
    echo ""
    echo "$HOOKS_CONTENT"
  fi
else
  # No settings file — create one
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  echo "{\"hooks\": $HOOKS_CONTENT}" | jq '.' > "$SETTINGS_FILE" 2>/dev/null || echo "{\"hooks\": $HOOKS_CONTENT}" > "$SETTINGS_FILE"
  info "Created $SETTINGS_FILE with hooks"
fi

ok

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
echo " Installation complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Add your sound files to: $INSTALL_DIR/"
echo "     See themes/$THEME/README.md for the file mapping guide."
echo ""
echo "  2. Test it:"
echo "     echo '{\"hook_event_name\":\"SessionStart\",\"session_id\":\"test\"}' | bash $INSTALL_DIR/play.sh"
echo ""
echo "  3. Restart Claude Code to activate the hooks."
echo ""
echo "  Optional: adjust volume or disable categories in your shell profile:"
echo "     export CLAUDE_SOUND_VOLUME=0.4"
echo "     export CLAUDE_SOUND_DISABLE=working"
echo ""
