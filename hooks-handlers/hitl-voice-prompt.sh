#!/usr/bin/env bash
# HITL Voice Prompt — Plays a sibling voice clip before AskUserQuestion
# PreToolUse hook on AskUserQuestion: generates or plays a voice prompt
# so the user hears a verbal cue before the HITL gate appears.
#
# Strategy:
#   1. Check voice cache for pre-generated clips (instant, zero API cost)
#   2. Fall back to SOUL CLI binary for dynamic TTS (2-5s cold start)
#   3. Fall back silently if neither works (never block the HITL)
#
# Voice selection: Claude by default (the engineer asking the question).
# CORSO/EVA skill-level voice is handled by the skill itself (richer context).
#
# Exit 0 always — never block the HITL interaction.

set -uo pipefail

SOUL_BIN="${HOME}/.soul/.config/bin/soul"
VOICE_CACHE="${HOME}/.soul/voice-cache/hitl"
CLAUDE_VOICE_ID="sB7vwSCyX0tQmU24cW2C"

# Pick a random cached clip if available
play_cached() {
  local dir="$1"
  if [ -d "$dir" ]; then
    local clips=("$dir"/*.mp3)
    if [ ${#clips[@]} -gt 0 ] && [ -f "${clips[0]}" ]; then
      local idx=$(( RANDOM % ${#clips[@]} ))
      if command -v afplay >/dev/null 2>&1; then
        afplay "${clips[$idx]}" &
      fi
      return 0
    fi
  fi
  return 1
}

# Try cached Claude pre-HITL clips first
if play_cached "${VOICE_CACHE}/claude/pre"; then
  exit 0
fi

# Fall back to SOUL CLI for dynamic TTS
if [ -x "$SOUL_BIN" ]; then
  OUTFILE="/tmp/soul-hitl-prompt.mp3"
  # Short prompt — Claude's calm voice
  "$SOUL_BIN" speak "Need your input on this one." \
    -V "$CLAUDE_VOICE_ID" \
    --output "$OUTFILE" >/dev/null 2>&1 &
  SOUL_PID=$!

  # Wait up to 8 seconds for the TTS to complete
  for i in $(seq 1 80); do
    if ! kill -0 "$SOUL_PID" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done

  # If file was generated, play it
  if [ -s "$OUTFILE" ]; then
    if command -v afplay >/dev/null 2>&1; then
      afplay "$OUTFILE" &
    fi
  fi
fi

exit 0
