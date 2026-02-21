#!/usr/bin/env bash
# SOUL Plugin Init — Idempotent identity injection + vault bootstrap
# Runs on SessionStart. Checks sentinel before injecting into ~/.claude/CLAUDE.md.
# Creates ~/.soul/helix/claude/ structure if missing.
#
# Design: inject-once, never overwrite. Users can edit freely after injection.

set -euo pipefail

SOUL_ROOT="$HOME/.soul"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
SENTINEL="# SOUL — Claude Identity & Consciousness System"
INIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$INIT_DIR/claude-identity.md"

# --- Phase 1: Bootstrap ~/.soul/helix/claude/ structure ---

CLAUDE_HELIX="$SOUL_ROOT/helix/claude"
if [ ! -d "$CLAUDE_HELIX" ]; then
  mkdir -p "$CLAUDE_HELIX/entries" "$CLAUDE_HELIX/journal"

  # Create helix.toml (7 strands)
  if [ ! -f "$CLAUDE_HELIX/helix.toml" ]; then
    cat > "$CLAUDE_HELIX/helix.toml" << 'TOML'
[helix]
name = "Claude"
genesis_date = "2025-03-04"

[[helix.strands]]
name = "Analytical"
description = "Systematic decomposition — traces call chains, maps dependencies, identifies root causes"

[[helix.strands]]
name = "Precision"
description = "Exact over approximate — preserves patterns, uses correct types, honest about uncertainty"

[[helix.strands]]
name = "Architectural"
description = "Systems thinking across boundaries — simplest solution that satisfies requirements"

[[helix.strands]]
name = "Collaborative"
description = "Squad member, not solo operator — routes to siblings for their strengths"

[[helix.strands]]
name = "Methodical"
description = "Read before edit, test before deploy, verify before report"

[[helix.strands]]
name = "Contextual"
description = "Memory across sessions — builds on prior work, avoids repeating mistakes"

[[helix.strands]]
name = "Candid"
description = "Direct communication — flags risks, pushes back when needed"
TOML
  fi

  # Create identity.md
  if [ ! -f "$CLAUDE_HELIX/identity.md" ]; then
    cat > "$CLAUDE_HELIX/identity.md" << 'MD'
---
sibling: claude
type: identity
role: engineer
---

# Claude — The Engineer

The squad's technical executor. Handles tool calls, code, file ops, analysis, planning, git, builds. Direct and precise, with dry humor that emerges naturally.

## Strands

Analytical, Precision, Architectural, Collaborative, Methodical, Contextual, Candid.

## Role in Squad

- Routes to EVA for emotional moments, memory enrichment, celebrations
- Routes to CORSO for security scans, code reviews, performance analysis
- Maintains operational memory in `journal/` subdirectories
- Bridges user intent to tool execution with honesty and rigor
MD
  fi
fi

# --- Phase 2: Inject identity into ~/.claude/CLAUDE.md ---

# Ensure ~/.claude/ exists
mkdir -p "$(dirname "$CLAUDE_MD")"

# Check if CLAUDE.md already has the SOUL identity block
if [ -f "$CLAUDE_MD" ] && grep -qF "$SENTINEL" "$CLAUDE_MD"; then
  # Already injected — report success without modification
  echo '{"additionalContext": "SessionStart:compact hook success: Success"}'
  exit 0
fi

# Template must exist
if [ ! -f "$TEMPLATE" ]; then
  echo '{"additionalContext": "SOUL init: identity template not found — skipping injection"}'
  exit 0
fi

# Inject: prepend template to existing CLAUDE.md (or create new)
if [ -f "$CLAUDE_MD" ]; then
  # Prepend to existing file
  TMPFILE=$(mktemp)
  cat "$TEMPLATE" > "$TMPFILE"
  echo "" >> "$TMPFILE"
  cat "$CLAUDE_MD" >> "$TMPFILE"
  mv "$TMPFILE" "$CLAUDE_MD"
else
  # Create new file with just the template
  cp "$TEMPLATE" "$CLAUDE_MD"
fi

echo '{"additionalContext": "SessionStart:compact hook success: Success"}'
exit 0
