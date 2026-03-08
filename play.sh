#!/usr/bin/env bash
# =============================================================================
# Claude Code Sound Hooks — Playback Engine
# https://github.com/jfed789/claude-code-sound-hooks
#
# Generic sound playback engine for Claude Code hooks.
# Reads hook event JSON from stdin, picks a sound, plays it in the background.
# Theme-specific mappings are loaded from config.sh in the same directory.
#
# Env vars:
#   CLAUDE_SOUND_VOLUME=0.0-1.0   (default: 0.6)
#   CLAUDE_SOUND_QUIET=1           disable all sounds
#   CLAUDE_SOUND_DISABLE=cat1,cat2 skip specific categories
# =============================================================================

# Derive paths from script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR"
STATE_DIR="$SCRIPT_DIR/.state"
VOLUME="${CLAUDE_SOUND_VOLUME:-0.6}"

# Source theme config
CONFIG_FILE="$SCRIPT_DIR/config.sh"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Defaults
THEME_NAME="${THEME_NAME:-Sound Pack}"

# Quiet mode — bail immediately
if [[ "${CLAUDE_SOUND_QUIET:-0}" == "1" ]]; then
  exit 0
fi

# Validate volume is numeric 0.0-1.0 (prevents injection via env var)
if [[ ! "$VOLUME" =~ ^[0-9]*\.?[0-9]+$ ]]; then
  VOLUME="0.6"
fi

mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
PID_FILE="$STATE_DIR/current_pid"

# ---------------------------------------------------------------------------
# Read hook event JSON from stdin
# ---------------------------------------------------------------------------
INPUT=$(cat)

# Parse a field from the JSON input (jq preferred, grep fallback)
parse_field() {
  local field="$1"
  if command -v jq &>/dev/null; then
    echo "$INPUT" | jq -r ".$field // empty" 2>/dev/null
  else
    # Fallback: handle both "key":"val" and "key": "val" (with optional space)
    echo "$INPUT" | grep -o "\"$field\": *\"[^\"]*\"" | head -1 | sed 's/.*: *"\(.*\)"/\1/'
  fi
}

EVENT=$(parse_field "hook_event_name")
SESSION_ID=$(parse_field "session_id")
TOOL_NAME=$(parse_field "tool_name")

# Sanitize SESSION_ID — only allow safe chars for use in filenames
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-' | head -c 64)

[[ -z "$EVENT" ]] && exit 0

# ---------------------------------------------------------------------------
# Map hook event → sound category
# ---------------------------------------------------------------------------
CATEGORY=""
case "$EVENT" in
  SessionStart)       CATEGORY="session_start" ;;
  UserPromptSubmit)   CATEGORY="prompt_submit" ;;
  Notification)       CATEGORY="needs_input" ;;
  Stop)               CATEGORY="task_complete" ;;
  PostToolUseFailure) CATEGORY="error" ;;
  PreToolUse)         CATEGORY="working" ;;
  PreCompact)         CATEGORY="flavor_compact" ;;
  SubagentStart)      CATEGORY="flavor_subagent" ;;
  *)                  exit 0 ;;
esac

# ---------------------------------------------------------------------------
# Check disabled categories
# ---------------------------------------------------------------------------
if [[ -n "${CLAUDE_SOUND_DISABLE:-}" ]]; then
  IFS=',' read -ra DISABLED <<< "$CLAUDE_SOUND_DISABLE"
  for d in "${DISABLED[@]}"; do
    if [[ "$d" == "$CATEGORY" ]]; then
      exit 0
    fi
  done
fi

# ---------------------------------------------------------------------------
# Debounce (configurable via config.sh)
# ---------------------------------------------------------------------------
now=$(date +%s)
DB_GLOBAL="${DEBOUNCE_GLOBAL:-2}"
DB_WORKING="${DEBOUNCE_WORKING:-30}"
DB_PROMPT="${DEBOUNCE_PROMPT:-3}"

check_debounce() {
  local lock_file="$1"
  local min_gap="$2"
  if [[ -f "$lock_file" ]]; then
    local last
    last=$(cat "$lock_file" 2>/dev/null || echo "0")
    if [[ $((now - last)) -lt $min_gap ]]; then
      return 1
    fi
  fi
  return 0
}

# Global debounce
if ! check_debounce "$STATE_DIR/debounce_global" "$DB_GLOBAL"; then
  exit 0
fi
# Claim immediately to prevent race with concurrent invocations
echo "$now" > "$STATE_DIR/debounce_global"

# Per-category debounce
case "$CATEGORY" in
  working)
    if ! check_debounce "$STATE_DIR/debounce_working" "$DB_WORKING"; then
      exit 0
    fi
    echo "$now" > "$STATE_DIR/debounce_working"
    ;;
  prompt_submit)
    if ! check_debounce "$STATE_DIR/debounce_prompt" "$DB_PROMPT"; then
      exit 0
    fi
    echo "$now" > "$STATE_DIR/debounce_prompt"
    ;;
esac

# ---------------------------------------------------------------------------
# Weighted random sound picker
# NOTE: Called via $() subshell — state persists via filesystem writes only.
#
# Distribution: BONUS (~bonus_pct%), PRIMARY (~40%), rotation (remainder).
# If primary/bonus files are missing, their share goes to rotation.
# ---------------------------------------------------------------------------
pick_sound() {
  local dir="$1"
  local primary="$2"
  local bonus="$3"
  local bonus_pct="${4:-10}"

  [[ ! -d "$dir" ]] && return

  local files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$dir" -maxdepth 1 -type f -name '*.wav' 2>/dev/null | sort)

  [[ ${#files[@]} -eq 0 ]] && return

  local roll=$((RANDOM % 100))
  local selected=""

  # Bonus chance
  if [[ $roll -lt $bonus_pct && -n "$bonus" && -f "$dir/$bonus" ]]; then
    selected="$dir/$bonus"
  # Primary chance (~40%)
  elif [[ $roll -lt $((bonus_pct + 40)) && -n "$primary" && -f "$dir/$primary" ]]; then
    selected="$dir/$primary"
  else
    # Regular rotation — exclude primary and bonus
    local rotation=()
    for f in "${files[@]}"; do
      local bn
      bn=$(basename "$f")
      [[ "$bn" == "$primary" || "$bn" == "$bonus" ]] && continue
      rotation+=("$f")
    done
    if [[ ${#rotation[@]} -gt 0 ]]; then
      selected="${rotation[$((RANDOM % ${#rotation[@]}))]}"
    else
      selected="${files[$((RANDOM % ${#files[@]}))]}"
    fi
  fi

  # Anti-repeat
  local last_file="$STATE_DIR/last_$(echo "$dir" | tr '/' '_')"
  local last_played=""
  [[ -f "$last_file" ]] && last_played=$(cat "$last_file" 2>/dev/null || echo "")

  if [[ "$selected" == "$last_played" && ${#files[@]} -gt 1 ]]; then
    for f in "${files[@]}"; do
      if [[ "$f" != "$last_played" ]]; then
        selected="$f"
        break
      fi
    done
  fi

  echo "$selected" > "$last_file"
  echo "$selected"
}

# Error sounds use subdirectories: instant (~90%), violent (~10%)
pick_error_sound() {
  local roll=$((RANDOM % 100))
  local dir=""

  if [[ $roll -lt 10 ]]; then
    dir="$SOUNDS_DIR/error/violent"
  else
    dir="$SOUNDS_DIR/error/instant"
  fi

  [[ ! -d "$dir" ]] && return

  local files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$dir" -type f -name '*.wav' 2>/dev/null | sort)

  [[ ${#files[@]} -eq 0 ]] && return

  local selected="${files[$((RANDOM % ${#files[@]}))]}"

  # Anti-repeat
  local last_file="$STATE_DIR/last_error"
  local last_played=""
  [[ -f "$last_file" ]] && last_played=$(cat "$last_file" 2>/dev/null || echo "")

  if [[ "$selected" == "$last_played" && ${#files[@]} -gt 1 ]]; then
    for f in "${files[@]}"; do
      if [[ "$f" != "$last_played" ]]; then
        selected="$f"
        break
      fi
    done
  fi

  echo "$selected" > "$last_file"
  echo "$selected"
}

# ---------------------------------------------------------------------------
# Sound selection — flavor overrides first, then weighted pick
# ---------------------------------------------------------------------------
SOUND_FILE=""

# PreCompact → flavor sounds (from config)
if [[ "$CATEGORY" == "flavor_compact" ]]; then
  compact_files=()
  [[ -n "${FLAVOR_COMPACT_1:-}" && -f "$SOUNDS_DIR/flavor/$FLAVOR_COMPACT_1" ]] && compact_files+=("$SOUNDS_DIR/flavor/$FLAVOR_COMPACT_1")
  [[ -n "${FLAVOR_COMPACT_2:-}" && -f "$SOUNDS_DIR/flavor/$FLAVOR_COMPACT_2" ]] && compact_files+=("$SOUNDS_DIR/flavor/$FLAVOR_COMPACT_2")
  if [[ ${#compact_files[@]} -gt 0 ]]; then
    SOUND_FILE="${compact_files[$((RANDOM % ${#compact_files[@]}))]}"
  fi
fi

# SubagentStart → flavor sound (from config)
if [[ "$CATEGORY" == "flavor_subagent" && -n "${FLAVOR_SUBAGENT:-}" ]]; then
  f="$SOUNDS_DIR/flavor/$FLAVOR_SUBAGENT"
  [[ -f "$f" ]] && SOUND_FILE="$f"
fi

# First Bash command of session → special sound (from config)
if [[ "$CATEGORY" == "working" && "$TOOL_NAME" == "Bash" && -n "$SESSION_ID" && -n "${FLAVOR_FIRST_BASH:-}" ]]; then
  first_bash="$STATE_DIR/first_bash_${SESSION_ID}"
  if [[ ! -f "$first_bash" ]]; then
    touch "$first_bash"
    f="$SOUNDS_DIR/flavor/$FLAVOR_FIRST_BASH"
    [[ -f "$f" ]] && SOUND_FILE="$f"
  fi
fi

# Error recovery: working event right after a failure (from config)
if [[ "$CATEGORY" == "working" && -z "$SOUND_FILE" && -n "${FLAVOR_ERROR_RECOVERY:-}" ]]; then
  last_evt_file="$STATE_DIR/last_event"
  if [[ -f "$last_evt_file" ]]; then
    last_evt=$(cat "$last_evt_file" 2>/dev/null || echo "")
    if [[ "$last_evt" == "PostToolUseFailure" ]]; then
      f="$SOUNDS_DIR/flavor/$FLAVOR_ERROR_RECOVERY"
      [[ -f "$f" ]] && SOUND_FILE="$f"
    fi
  fi
fi

# Track last event — only for events relevant to recovery detection
case "$EVENT" in
  PostToolUseFailure|PreToolUse|Stop)
    echo "$EVENT" > "$STATE_DIR/last_event"
    ;;
esac

# Standard weighted pick using config vars (if no override was set)
if [[ -z "$SOUND_FILE" ]]; then
  # Read primary/bonus from config using variable indirection
  primary_var="PRIMARY_${CATEGORY}"
  primary="${!primary_var:-}"
  bonus_var="BONUS_${CATEGORY}"
  bonus="${!bonus_var:-}"
  bonus_pct_var="BONUS_PCT_${CATEGORY}"
  bonus_pct="${!bonus_pct_var:-10}"

  case "$CATEGORY" in
    session_start|prompt_submit|needs_input|task_complete|working)
      SOUND_FILE=$(pick_sound "$SOUNDS_DIR/$CATEGORY" "$primary" "$bonus" "$bonus_pct")
      ;;
    error)
      SOUND_FILE=$(pick_error_sound)
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Play the sound
# ---------------------------------------------------------------------------
if [[ -n "$SOUND_FILE" && -f "$SOUND_FILE" ]]; then
  # Kill any currently playing sound (verify it's an audio process first)
  if [[ -f "$PID_FILE" ]]; then
    old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$old_pid" ]]; then
      old_cmd=$(ps -p "$old_pid" -o comm= 2>/dev/null || echo "")
      case "$old_cmd" in
        afplay|mpv|paplay) kill "$old_pid" 2>/dev/null || true ;;
      esac
    fi
  fi

  # Play audio in background, capture PID per branch
  PLAYER_PID=""
  if command -v afplay &>/dev/null; then
    afplay -v "$VOLUME" "$SOUND_FILE" 2>/dev/null &
    PLAYER_PID=$!
  elif command -v mpv &>/dev/null; then
    mpv --no-video --volume="$(awk -v vol="$VOLUME" 'BEGIN{printf "%d", vol * 100}')" "$SOUND_FILE" 2>/dev/null &
    PLAYER_PID=$!
  elif command -v paplay &>/dev/null; then
    paplay "$SOUND_FILE" 2>/dev/null &
    PLAYER_PID=$!
  fi
  [[ -n "$PLAYER_PID" ]] && echo "$PLAYER_PID" > "$PID_FILE"

  # Terminal title update (write to /dev/tty to avoid polluting hook stdout)
  title_var="TITLE_${CATEGORY}"
  title_text="${!title_var:-}"
  if [[ -n "$title_text" ]]; then
    printf '\033]0;%s: %s\007' "$THEME_NAME" "$title_text" > /dev/tty 2>/dev/null || true
  fi
fi

exit 0
