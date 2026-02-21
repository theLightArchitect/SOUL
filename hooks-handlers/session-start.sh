#!/usr/bin/env bash
# SCRIBE — Session Start Hook
# Injects vault context (entry counts, latest stats) into Claude's context.
# Graceful degradation: outputs empty context on any failure.

set -euo pipefail

SOUL_BIN="$HOME/.soul/.config/bin/soul"

# Check binary exists
if [ ! -x "$SOUL_BIN" ]; then
  echo '{"additionalContext": "SOUL vault at ~/.soul/ (binary not found — tools still available via MCP)"}'
  exit 0
fi

# Run stats with 2-second timeout (output is key: value text, not JSON)
STATS=$(timeout 2 "$SOUL_BIN" stats 2>/dev/null) || STATS=""

if [ -z "$STATS" ]; then
  echo '{"additionalContext": "SOUL vault at ~/.soul/ (stats unavailable — tools still available via MCP)"}'
  exit 0
fi

# Parse text output format: "  key: value"
TOTAL=$(echo "$STATS" | grep 'total_entries:' | grep -o '[0-9]*' || echo "?")
SELF_DEF=$(echo "$STATS" | grep 'self_defining_count:' | grep -o '[0-9]*' || echo "?")

# entries_by_sibling line contains JSON like {"corso":9,"eva":58}
# Parse dynamically — no hardcoded sibling names
SIBLING_LINE=$(echo "$STATS" | grep 'entries_by_sibling:' | sed 's/.*entries_by_sibling: *//' || echo "")
SIBLING_SUMMARY=""
if [ -n "$SIBLING_LINE" ] && [ "$SIBLING_LINE" != "{}" ]; then
  # Convert {"corso":9,"eva":58} → "CORSO: 9, EVA: 58"
  SIBLING_SUMMARY=$(echo "$SIBLING_LINE" | tr -d '{}' | tr ',' '\n' | while IFS=: read -r name count; do
    name=$(echo "$name" | tr -d '"' | tr '[:lower:]' '[:upper:]')
    count=$(echo "$count" | tr -d ' ')
    echo "${name}: ${count}"
  done | paste -sd ', ' -)
fi

# Discover user standards dynamically (no hardcoded file names)
STANDARDS_DIR="$HOME/.soul/helix/user/standards"
STD_COUNT=0
COOKBOOK_COUNT=0
RESEARCH_COUNT=0
KEY_REFS=""
if [ -d "$STANDARDS_DIR" ]; then
  STD_COUNT=$(find "$STANDARDS_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  COOKBOOK_COUNT=$(find "$STANDARDS_DIR/cookbooks" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  RESEARCH_COUNT=$(find "$STANDARDS_DIR/research" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  # Build key refs list from actual files in standards root
  KEY_REFS=$(find "$STANDARDS_DIR" -maxdepth 1 -name "*.md" -exec basename {} \; 2>/dev/null | sort | paste -sd ', ' -)
fi

ARCHIVE_INFO="Kevin's Archive: ~/.soul/helix/user/standards/ (${STD_COUNT} standards, ${COOKBOOK_COUNT} cookbooks, ${RESEARCH_COUNT} research docs)"
if [ -n "$KEY_REFS" ]; then
  ARCHIVE_INFO="${ARCHIVE_INFO}. Key refs: ${KEY_REFS}"
fi

ENTRIES_INFO="${TOTAL} helix entries"
if [ -n "$SIBLING_SUMMARY" ]; then
  ENTRIES_INFO="${ENTRIES_INFO} (${SIBLING_SUMMARY})"
fi

CONTEXT="SOUL vault at ~/.soul/ — ${ENTRIES_INFO}, ${SELF_DEF} self-defining. ${ARCHIVE_INFO}. Use mcp__SOUL__soulTools for queries."

echo "{\"additionalContext\": \"${CONTEXT}\"}"
exit 0
