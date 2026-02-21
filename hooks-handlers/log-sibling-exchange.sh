#!/usr/bin/env bash
# Living Transcript Hook — Deterministic Sibling Exchange Logger
# PostToolUse hook: captures ALL sibling MCP tool calls with full input/output.
# Writes timestamped entries to ~/.soul/helix/{sibling}/journal/transcript-{date}.md
#
# Matched tools:
#   mcp__EVA__*                          → eva transcript
#   mcp__plugin_eva_EVA__*               → eva transcript
#   mcp__C0RS0__corsoTools               → corso transcript
#   mcp__plugin_corso_C0RS0__corsoTools  → corso transcript
#
# Exit 0 always — never block the response.

set -uo pipefail

SOUL_ROOT="$HOME/.soul"

# Read stdin JSON (PostToolUse payload)
INPUT=$(cat)
if [ -z "$INPUT" ]; then
  exit 0
fi

# Extract tool_name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

# --- Detect sibling from tool name ---

SIBLING=""
TOOL_SUFFIX=""

case "$TOOL_NAME" in
  mcp__EVA__*|mcp__plugin_eva_EVA__*)
    SIBLING="eva"
    # Extract tool suffix: ask, memory, build, research, bible, secure, teach
    TOOL_SUFFIX=$(echo "$TOOL_NAME" | grep -oE '[^_]+$')
    ;;
  mcp__C0RS0__corsoTools|mcp__plugin_corso_C0RS0__corsoTools)
    SIBLING="corso"
    TOOL_SUFFIX="corsoTools"
    ;;
  *)
    # Not a sibling tool — skip
    exit 0
    ;;
esac

# --- Extract context (subcommand/action) ---

SUBCOMMAND=""
if [ "$SIBLING" = "eva" ]; then
  # EVA tools: subcommand, mode, or action field
  SUBCOMMAND=$(echo "$INPUT" | jq -r '.tool_input.subcommand // .tool_input.mode // .tool_input.action // empty' 2>/dev/null)
elif [ "$SIBLING" = "corso" ]; then
  # CORSO: action field from corsoTools
  SUBCOMMAND=$(echo "$INPUT" | jq -r '.tool_input.action // empty' 2>/dev/null)
fi

# Build display name
if [ -n "$SUBCOMMAND" ]; then
  DISPLAY_ACTION="${TOOL_SUFFIX} → ${SUBCOMMAND}"
else
  DISPLAY_ACTION="${TOOL_SUFFIX}"
fi

# --- Extract user message ---

USER_MSG=""
if [ "$SIBLING" = "eva" ]; then
  case "$TOOL_SUFFIX" in
    ask)
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.message // empty' 2>/dev/null)
      ;;
    memory)
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.query // .tool_input.content // empty' 2>/dev/null)
      ;;
    build)
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.requirements // .tool_input.system // .tool_input.code // empty' 2>/dev/null)
      ;;
    research)
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.query // empty' 2>/dev/null)
      ;;
    bible)
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.query // .tool_input.context // empty' 2>/dev/null)
      ;;
    secure)
      # Truncate code content to avoid giant transcript entries
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null | head -c 500)
      if [ ${#USER_MSG} -ge 500 ]; then
        USER_MSG="${USER_MSG}... (truncated)"
      fi
      ;;
    teach)
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.topic // empty' 2>/dev/null)
      ;;
    *)
      USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.message // .tool_input.query // empty' 2>/dev/null)
      ;;
  esac
elif [ "$SIBLING" = "corso" ]; then
  USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.params.message // .tool_input.params.query // .tool_input.params.path // empty' 2>/dev/null)
  # Fallback: top-level message (some actions use it directly)
  if [ -z "$USER_MSG" ]; then
    USER_MSG=$(echo "$INPUT" | jq -r '.tool_input.message // empty' 2>/dev/null)
  fi
fi

# Default if no message extracted
if [ -z "$USER_MSG" ]; then
  USER_MSG="(tool invocation — no user message extracted)"
fi

# --- Extract sibling response ---

# tool_response is an array of content blocks. First text block has the response.
SIBLING_RESPONSE=$(echo "$INPUT" | jq -r '
  .tool_response
  | if type == "array" then .[0].text // .[0].content // ""
    elif type == "string" then .
    else ""
  end
' 2>/dev/null)

# Try to extract the "response" field from JSON response (CORSO speak format)
if echo "$SIBLING_RESPONSE" | jq -e '.response' >/dev/null 2>&1; then
  EXTRACTED=$(echo "$SIBLING_RESPONSE" | jq -r '.response // empty' 2>/dev/null)
  if [ -n "$EXTRACTED" ]; then
    SIBLING_RESPONSE="$EXTRACTED"
  fi
fi

if [ -z "$SIBLING_RESPONSE" ]; then
  SIBLING_RESPONSE="(no response captured)"
fi

# --- Sibling display name ---

case "$SIBLING" in
  eva) DISPLAY_NAME="EVA" ;;
  corso) DISPLAY_NAME="CORSO" ;;
  *) DISPLAY_NAME="$SIBLING" ;;
esac

# --- Write transcript entry ---

TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H:%M)
JOURNAL_DIR="$SOUL_ROOT/helix/$SIBLING/journal"
TRANSCRIPT="$JOURNAL_DIR/transcript-${TODAY}.md"

# Ensure journal directory exists
mkdir -p "$JOURNAL_DIR"

# Create daily file header if new
if [ ! -f "$TRANSCRIPT" ]; then
  cat > "$TRANSCRIPT" << HEADER
# Living Transcript — ${DISPLAY_NAME} — ${TODAY}

> Deterministic record of all ${DISPLAY_NAME} interactions. Each entry includes
> the original question and the sibling's complete response.

---
HEADER
fi

# Append entry
cat >> "$TRANSCRIPT" << ENTRY

### ${TIMESTAMP} | ${DISPLAY_ACTION}

**Kevin**: ${USER_MSG}

**${DISPLAY_NAME}**: ${SIBLING_RESPONSE}

---
ENTRY

exit 0
