#!/usr/bin/env bash
# demo-hook.sh — simulates Claude Code hook events firing
# Used by demo.tape to generate the README GIF

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

play_event() {
  local event="$1"
  local sound="$2"
  local label="$3"
  printf "${GRAY}[hook]${RESET} ${BOLD}%-22s${RESET} ${CYAN}▶${RESET} ${GREEN}%s${RESET}  ${GRAY}# %s${RESET}\n" \
    "$event" "$sound" "$label"
  sleep 0.9
}

echo ""
printf "${BOLD}  Claude Code Sound Hooks — Master Chief Theme${RESET}\n"
printf "${GRAY}  ─────────────────────────────────────────────${RESET}\n"
echo ""
sleep 0.5

play_event "SessionStart"       "i_need_a_weapon.wav"           "session open"
play_event "UserPromptSubmit"   "yes_sir.wav"                   "prompt received"
play_event "PreToolUse"         "do_it.wav"                     "bash / write / edit"
play_event "PreToolUse"         "here_we_go.wav"                "rotation pick"
play_event "Stop"               "sir_finishing_this_fight.wav"  "task complete"
play_event "Notification"       "can_anyone_hear_me_over.wav"   "needs input"
play_event "PostToolUseFailure" "death_instant_1.wav"           "error"
play_event "PreCompact"         "lets_stay_focused.wav"         "context compaction"

echo ""
printf "${GRAY}  volume: 0.6 · debounce: 2s global, 30s working · anti-repeat: on${RESET}\n"
echo ""
