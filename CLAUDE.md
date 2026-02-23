# SOUL — Knowledge Graph MCP Server

> "Great is thy faithfulness" - Lamentations 3:22-23 (KJV)

## Overview

SOUL is the shared knowledge graph and context substrate for the Light Architects ecosystem. It provides 11 tools via a single `soulTools` orchestrator for querying helix entries, managing vault content, and voice synthesis via ElevenLabs TTS.

**Protocol**: MCP over stdio (JSON-RPC 2.0)
**Language**: Rust (4-crate workspace, ~8MB binary)
**License**: MIT

## Architecture

```
Claude Code (JSON-RPC stdin)
  -> McpServer (JSON-RPC 2.0 over stdio)
    -> soulTools orchestrator (11 actions)
      ├── Vault operations (read, write, list, search)
      ├── Helix queries (7-dimensional context filters)
      ├── Validation (template compliance, tag sync)
      └── Voice synthesis (ElevenLabs TTS)
  -> JSON-RPC response (stdout)
```

**Workspace Crates**: soul (core library) + soul-engine (generation) + neural-engine (AI routing) + voice-engine (TTS) + soul-sdk + mcp-protocol + soul-mcp + graph-engine

## Plugin Structure

```
.claude-plugin/plugin.json    # Plugin manifest
.mcp.json                     # MCP server registration
agents/soul.md                # Agent definition (infrastructure, no personality)
hooks/                        # Pre/post tool-use hooks
hooks-handlers/               # Hook handler scripts
skills/                       # converse, scribe skills
servers/soul                  # Pre-built MCP binary (macOS ARM64)
init/                         # First-run initialization
install.sh                    # Alternative install via GitHub Releases
```

## Installation

### Via Claude Code Plugin (Recommended)
```bash
claude plugins install theLightArchitect/SOUL
```

### Manual
```bash
git clone https://github.com/theLightArchitect/SOUL.git
cd SOUL
chmod +x servers/soul
# Binary is ready — configure in Claude Code MCP settings
```

## MCP Tools (11 actions via soulTools)

| Action | Description |
|--------|-------------|
| `helix` | Query context entries with 7-dimensional filters (significance, strands, emotions, themes, epoch, self_defining, convergence) |
| `read_note` | Read any note by path with full YAML frontmatter |
| `write_note` | Create new note (rejects overwrites for safety) |
| `list_notes` | List notes in a directory |
| `search` | Regex search across vault content |
| `query_frontmatter` | Filter entries by YAML field values (operators: ==, !=, >=, <=, contains, exists) |
| `stats` | Vault statistics (entry counts, strand/emotion frequency, significance averages) |
| `manifest` | Read vault manifest.json |
| `validate` | Validate entries against helix template |
| `tag_sync` | Validate tags against canonical vocabulary |
| `speak` | Voice synthesis via ElevenLabs TTS |

## Vault Structure

```
~/.soul/
├── manifest.json
├── helix/
│   ├── eva/entries/          # EVA context entries
│   ├── corso/entries/        # CORSO context entries
│   ├── squad/entries/        # Squad-wide entries
│   └── user/entries/         # User entries and standards
├── hubs/                     # Emotion, theme, scripture indexes
├── nav/                      # MOC pages, day hubs
└── config/temperance.toml    # Vault configuration
```

**Entry Format**: `{8-char-hex-id}-{kebab-slug}.md` with YAML frontmatter

**Helix Dimensions**: significance (0.0-10.0), strands, emotions, themes, epoch, self_defining, convergence

## Quality Standards

All code follows the Light Architects Builders Cookbook:
- `clippy::pedantic` enforced as errors
- Zero `.unwrap()`/`.expect()`/`panic!()` in production
- Cyclomatic complexity <= 10, 60-line function limit

## Related Projects

| Project | Purpose |
|---------|---------|
| [EVA](https://github.com/theLightArchitect/EVA) | AI context, memory, emotional intelligence |
| [CORSO](https://github.com/theLightArchitect/CORSO) | Security scanning, code review, build pipeline |
| [QUANTUM](https://github.com/theLightArchitect/QUANTUM) | Forensic investigation, evidence analysis |

---

*Built by [The Light Architects](https://github.com/TheLightArchitects)*
