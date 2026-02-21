#!/usr/bin/env bash
# Auto-Play Voice Hook — Plays synthesized audio after speak actions
# PostToolUse hook: detects speak responses from SOUL, EVA, and CORSO, plays audio via afplay.
#
# Matched tools:
#   mcp__SOUL__soulTools (action: "speak")          — canonical TTS path
#   mcp__plugin_soul_SOUL__soulTools (action: "speak")
#   mcp__EVA__ask (subcommand: "speak")             — EVA voice generation
#   mcp__plugin_eva_EVA__ask (subcommand: "speak")
#   mcp__C0RS0__corsoTools (action: "speak")        — CORSO (if audio returned)
#   mcp__plugin_corso_C0RS0__corsoTools (action: "speak")
#
# Strategy:
#   1. Checks `action` or `subcommand` field for "speak" value
#   2. Fast path: looks for `audio_file` on disk (server-side write)
#   3. Fallback: extracts base64 from response and decodes
#
# Exit 0 always — never block the response.

set -uo pipefail

# === DEBUG LOGGING (temporary — remove after validation) ===
DEBUG_LOG="/tmp/soul-hook-debug.log"
debug() { echo "[$(date '+%H:%M:%S')] $*" >> "$DEBUG_LOG"; }
debug "=== AUTO-PLAY HOOK FIRED ==="

# Temp files — cleaned up on exit
PAYLOAD_FILE=$(mktemp /tmp/soul-hook-payload.XXXXXX)
INNER_JSON_FILE=$(mktemp /tmp/soul-hook-inner.XXXXXX)
cleanup() { rm -f "$PAYLOAD_FILE" "$INNER_JSON_FILE" 2>/dev/null; }
trap cleanup EXIT

# Read stdin directly to file (avoids storing large payloads in bash variables)
cat > "$PAYLOAD_FILE"
if [ ! -s "$PAYLOAD_FILE" ]; then
  debug "EXIT: empty payload"
  exit 0
fi
debug "payload size: $(wc -c < "$PAYLOAD_FILE") bytes"

# Check for speak action OR subcommand
# SOUL/CORSO use "action", EVA uses "subcommand" — check both
SPEAK_FIELD=$(jq -r '
  .tool_input
  | if .action == "speak" then "speak"
    elif .subcommand == "speak" then "speak"
    else empty
  end
' "$PAYLOAD_FILE" 2>/dev/null)

debug "speak_field: '$SPEAK_FIELD'"
if [ "$SPEAK_FIELD" != "speak" ]; then
  debug "EXIT: not a speak call"
  exit 0
fi

# Extract the inner JSON text from tool_response
# tool_response is either an array [{type, text}] or a string
jq -r '
  .tool_response
  | if type == "array" then .[0].text else . end
' "$PAYLOAD_FILE" > "$INNER_JSON_FILE" 2>/dev/null

if [ ! -s "$INNER_JSON_FILE" ]; then
  debug "EXIT: inner JSON empty"
  debug "raw tool_response type: $(jq -r '.tool_response | type' "$PAYLOAD_FILE" 2>/dev/null)"
  exit 0
fi
debug "inner JSON size: $(wc -c < "$INNER_JSON_FILE") bytes"
debug "inner JSON keys: $(jq -r 'keys | join(",")' "$INNER_JSON_FILE" 2>/dev/null)"

# === FAST PATH: Check for audio_file (server-side disk write) ===
AUDIO_FILE=$(jq -r '.audio_file // empty' "$INNER_JSON_FILE" 2>/dev/null)
debug "audio_file: '$AUDIO_FILE'"
if [ -n "$AUDIO_FILE" ] && [ -s "$AUDIO_FILE" ]; then
  debug "FAST PATH: playing $AUDIO_FILE"
  if command -v afplay >/dev/null 2>&1; then
    afplay "$AUDIO_FILE" &
  fi
  exit 0
fi

# === FALLBACK: Extract base64 from response ===
HAS_AUDIO=$(jq -r 'has("audio_base64")' "$INNER_JSON_FILE" 2>/dev/null)
if [ "$HAS_AUDIO" != "true" ]; then
  debug "EXIT: no audio_file or audio_base64 in response"
  exit 0
fi

VOICE_ID=$(jq -r '.voice_id // "unknown"' "$INNER_JSON_FILE" 2>/dev/null)
FALLBACK_FILE="/tmp/soul-voice-${VOICE_ID}.mp3"

# Extract base64 to temp file and decode (file-to-file, no echo piping)
B64_FILE=$(mktemp /tmp/soul-hook-b64.XXXXXX)
jq -r '.audio_base64' "$INNER_JSON_FILE" > "$B64_FILE" 2>/dev/null
if [ -s "$B64_FILE" ]; then
  base64 -d < "$B64_FILE" > "$FALLBACK_FILE" 2>/dev/null
  rm -f "$B64_FILE"
  if [ -s "$FALLBACK_FILE" ]; then
    debug "FALLBACK: playing $FALLBACK_FILE"
    if command -v afplay >/dev/null 2>&1; then
      afplay "$FALLBACK_FILE" &
    fi
  fi
else
  rm -f "$B64_FILE"
fi

exit 0
