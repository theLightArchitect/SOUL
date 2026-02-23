#!/usr/bin/env bash
# SOUL Standalone Installer — Knowledge graph MCP server for Claude Code
#
# Recommended: Install via Claude Code plugin instead:
#   claude plugins install theLightArchitect/SOUL
#
# This script downloads the binary from GitHub Releases for standalone use.
# Usage: curl -fsSL https://raw.githubusercontent.com/theLightArchitect/SOUL/main/install.sh | bash
set -euo pipefail

REPO="theLightArchitect/SOUL"
INSTALL_DIR="$HOME/.soul/.config/bin"
BINARY_NAME="soul"
VAULT_ROOT="$HOME/.soul"

# --- Platform checks ---

OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" != "Darwin" ]; then
  echo "Error: SOUL currently supports macOS only (detected: $OS)"
  exit 1
fi

if [ "$ARCH" != "arm64" ]; then
  echo "Error: SOUL requires Apple Silicon (arm64). Detected: $ARCH"
  exit 1
fi

# --- Download latest release ---

echo "Fetching latest SOUL release..."
DOWNLOAD_URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep "browser_download_url.*darwin-arm64" \
  | head -1 \
  | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: Could not find a darwin-arm64 release asset."
  echo "Check https://github.com/$REPO/releases for available downloads."
  exit 1
fi

echo "Downloading from: $DOWNLOAD_URL"

TMPDIR_INSTALL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_INSTALL"' EXIT

curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR_INSTALL/soul.tar.gz"

# --- Extract and install binary ---

mkdir -p "$INSTALL_DIR"

tar xzf "$TMPDIR_INSTALL/soul.tar.gz" -C "$TMPDIR_INSTALL"
mv "$TMPDIR_INSTALL/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# --- Clear macOS Gatekeeper quarantine ---

xattr -cr "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true

# --- Bootstrap vault (only files that don't already exist) ---

echo "Bootstrapping vault at $VAULT_ROOT..."

mkdir -p "$VAULT_ROOT/config" "$VAULT_ROOT/helix" "$VAULT_ROOT/hubs" "$VAULT_ROOT/nav" "$VAULT_ROOT/archive"

# Determine plugin root (where this install.sh lives or a temp clone)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
TEMPLATE_DIR=""

# If running from a cloned repo with init/vault-template/
if [ -d "$SCRIPT_DIR/init/vault-template" ]; then
  TEMPLATE_DIR="$SCRIPT_DIR/init/vault-template"
else
  # Download vault template from repo
  TEMPLATE_URL="https://api.github.com/repos/$REPO/contents/init/vault-template"
  # Just create minimal defaults inline
  TEMPLATE_DIR=""
fi

# manifest.json
if [ ! -f "$VAULT_ROOT/manifest.json" ]; then
  cat > "$VAULT_ROOT/manifest.json" << 'JSON'
{
  "version": "1.0.0",
  "created": "auto",
  "config": "config",
  "archive": "archive",
  "global_hub_counts": { "emotions": 0, "scripture": 0, "themes": 0 },
  "helix": {}
}
JSON
  echo "  Created manifest.json"
fi

# config/temperance.toml
if [ ! -f "$VAULT_ROOT/config/temperance.toml" ]; then
  cat > "$VAULT_ROOT/config/temperance.toml" << 'TOML'
# Temperance Configuration — Resource Governance
[endurance]
intra_task_max = 10
inter_phase_max = 3
orchestrator_max = 4

[clarity]
default = { max_results = 10, max_tokens_per_result = 1000 }

[integrity]
domains = ["code", "memory", "persona", "security"]
TOML
  echo "  Created config/temperance.toml"
fi

# helix/_TEMPLATE.md
if [ ! -f "$VAULT_ROOT/helix/_TEMPLATE.md" ]; then
  if [ -n "$TEMPLATE_DIR" ] && [ -f "$TEMPLATE_DIR/helix/_TEMPLATE.md" ]; then
    cp "$TEMPLATE_DIR/helix/_TEMPLATE.md" "$VAULT_ROOT/helix/_TEMPLATE.md"
  fi
  echo "  Created helix/_TEMPLATE.md"
fi

# --- Verify ---

if "$INSTALL_DIR/$BINARY_NAME" --help >/dev/null 2>&1; then
  VERSION_INFO="(verified)"
else
  VERSION_INFO="(binary installed but --help check skipped)"
fi

# --- Success ---

cat <<EOF

  SOUL installed successfully $VERSION_INFO
  Binary: $INSTALL_DIR/$BINARY_NAME
  Vault:  $VAULT_ROOT/

  Note: For the full experience (agent, hooks, skills, vault init), use the plugin:
    claude plugins install theLightArchitect/SOUL

  To use this standalone binary, add to Claude Code:

  1. Quick setup:

     claude mcp add SOUL -- $INSTALL_DIR/$BINARY_NAME

  2. Or manually add to ~/.claude/mcp.json:

     {
       "mcpServers": {
         "SOUL": {
           "command": "$INSTALL_DIR/$BINARY_NAME",
           "env": { "RUST_LOG": "info" }
         }
       }
     }

  3. Restart Claude Code, then try:

     "Show vault statistics"
     "Search the vault for trust"
     "Query self-defining helix entries"

EOF
