#!/usr/bin/env bash
# HITL Voice Acknowledgment — Plays a sibling voice clip after AskUserQuestion
# PostToolUse hook on AskUserQuestion: generates or plays a voice acknowledgment
# so the user hears a verbal cue after making their HITL selection.
#
# Strategy:
#   1. Check voice cache for pre-generated clips (instant, zero API cost)
#   2. Fall back to SOUL CLI binary for dynamic TTS
#   3. Fall back silently if neither works (never block)
#
# Exit 0 always — never block.

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

# Try cached Claude post-HITL clips first
if play_cached "${VOICE_CACHE}/claude/post"; then
  exit 0
fi

# Fall back to SOUL CLI for dynamic TTS
if [ -x "$SOUL_BIN" ]; then
  OUTFILE="/tmp/soul-hitl-ack.mp3"
  "$SOUL_BIN" speak "Got it. Proceeding." \
    -V "$CLAUDE_VOICE_ID" \
    --output "$OUTFILE" >/dev/null 2>&1 &
  SOUL_PID=$!

  for i in $(seq 1 80); do
    if ! kill -0 "$SOUL_PID" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done

  if [ -s "$OUTFILE" ]; then
    if command -v afplay >/dev/null 2>&1; then
      afplay "$OUTFILE" &
    fi
  fi
fi

exit 0
