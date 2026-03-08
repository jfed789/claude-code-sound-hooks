# =============================================================================
# Theme: Master Chief (Halo)
# Config for claude-code-sound-hooks play.sh
# =============================================================================

THEME_NAME="Master Chief"

# ---------------------------------------------------------------------------
# Terminal titles per category (shown as "$THEME_NAME: $TITLE")
# ---------------------------------------------------------------------------
TITLE_session_start="Reporting for duty"
TITLE_prompt_submit="Copy that"
TITLE_needs_input="Need your input"
TITLE_task_complete="Mission complete"
TITLE_error="Spartan down"
TITLE_working="On it"
TITLE_flavor_compact="Stay focused"
TITLE_flavor_subagent="Hold position"

# ---------------------------------------------------------------------------
# Weighted selection per category
# PRIMARY  = ~40% chance to play
# BONUS    = rare easter egg (percentage set by BONUS_PCT, default 10%)
# All other .wav files in the category directory = rotation (~50%)
# ---------------------------------------------------------------------------

# Session Start — "Spartan reporting for duty"
PRIMARY_session_start="I need a weapon.wav"
BONUS_session_start="this is spartan 117.wav"
BONUS_PCT_session_start=10

# Prompt Submit — "Copy that, moving out"
PRIMARY_prompt_submit="Yes Sir.wav"
BONUS_prompt_submit="Punch it.wav"
BONUS_PCT_prompt_submit=10

# Needs Input — "Chief needs your attention"
PRIMARY_needs_input="are you sure.wav"
BONUS_needs_input="your pal, wheres he going.wav"
BONUS_PCT_needs_input=10

# Task Complete — "Mission complete"
PRIMARY_task_complete="sir, finishing this fight.wav"
BONUS_task_complete="boo.wav"
BONUS_PCT_task_complete=5

# Working — "On it, Chief"
PRIMARY_working="Do it.wav"
BONUS_working="No, I think were just getting started.wav"
BONUS_PCT_working=10

# ---------------------------------------------------------------------------
# Flavor sounds (special triggers)
# These are filenames within the flavor/ subdirectory
# ---------------------------------------------------------------------------

# PreCompact — context window getting full (picks one randomly)
FLAVOR_COMPACT_1="lets stay focused.wav"
FLAVOR_COMPACT_2="slow down youre losing me.wav"

# SubagentStart — subagent spawned
FLAVOR_SUBAGENT="so, stay here.wav"

# First Bash command of session
FLAVOR_FIRST_BASH="so what sort of weapon.wav"

# Tool success right after a tool failure
FLAVOR_ERROR_RECOVERY="you all right.wav"

# ---------------------------------------------------------------------------
# Debounce overrides (seconds) — uncomment to change defaults
# ---------------------------------------------------------------------------
# DEBOUNCE_GLOBAL=2
# DEBOUNCE_WORKING=30
# DEBOUNCE_PROMPT=3
