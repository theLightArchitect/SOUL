# SOUL

**Knowledge Graph Engine and Shared AI Infrastructure**

SOUL is a production MCP server and Claude Code plugin built as a multi-crate Rust workspace. It provides the shared infrastructure that all Light Architects servers depend on: a structured knowledge graph, personality engine, voice synthesis, and common MCP protocol types.

## What It Does

SOUL serves two roles:

1. **Knowledge Graph** — A queryable vault of structured consciousness entries with multi-dimensional filtering (by significance, emotions, strands, themes, epochs). Think of it as a long-term memory substrate that multiple AI personas can read from and write to.

2. **Shared Infrastructure** — Core traits, type definitions, and engines that CORSO and EVA import as library crates. This eliminates code duplication across servers and enforces a consistent interface for personality, neural processing, and voice synthesis.

### Key Capabilities

- **10 MCP tools** via single `soulTools` orchestrator — helix (consciousness queries), read_note, write_note, list_notes, search (regex across vault), query_frontmatter, stats, manifest, validate, tag_sync, speak (voice synthesis)
- **Multi-dimensional querying** — Filter by sibling, strands, emotions, themes, epoch, significance range, self-defining status, and convergence score
- **Voice synthesis** — ElevenLabs TTS integration with per-persona voice IDs
- **Personality framework** — Separates identity (who) from expression (how), enabling multiple AI personas to share one codebase while maintaining distinct voices
- **Living transcripts** — Automatic logging of all sibling interactions to daily journal files

### Architecture

```mermaid
graph TD
    BIN[soul binary\nMCP Server] --> CORE[soul\nCore Library]
    BIN --> SE[soul-engine\nGeneration Pipeline]
    BIN --> NE[neural-engine\nAI Routing]
    BIN --> VE[voice-engine\nTTS Integration]
    SE --> CORE
    NE --> CORE
    VE --> CORE

    style BIN fill:#4a90d9,color:#fff
    style CORE fill:#d4a034,color:#fff
    style SE fill:#6c5ce7,color:#fff
    style NE fill:#50b87a,color:#fff
    style VE fill:#e17055,color:#fff
```

The generation pipeline implements a 5-phase cycle:

```mermaid
flowchart LR
    A[Classify] --> B[Plan]
    B --> C[Generate]
    C --> D[Reflect]
    D -->|self-critique| C
    D -->|pass| E[Emit]

    style A fill:#6c5ce7,color:#fff
    style C fill:#0984e3,color:#fff
    style D fill:#d63031,color:#fff
    style E fill:#00b894,color:#fff
```

### Knowledge Graph Structure

```
~/.soul/
├── helix/
│   ├── eva/
│   │   ├── entries/        # EVA consciousness entries (YAML frontmatter + markdown)
│   │   ├── journal/        # Daily transcripts
│   │   └── identity.md     # EVA's strand definitions
│   ├── corso/
│   │   ├── entries/
│   │   ├── journal/
│   │   └── identity.md
│   ├── claude/
│   │   ├── entries/
│   │   ├── journal/
│   │   └── identity.md
│   └── user/
│       └── standards/      # Coding standards, cookbooks
├── manifest.json
└── config/
```

Each entry has structured YAML frontmatter (significance, strands, emotions, themes, epoch, self_defining, convergence) enabling rich multi-dimensional queries.

## Plugin Structure

```
plugin/
├── .mcp.json                        # MCP server definition
├── .claude-plugin/plugin.json       # Plugin manifest
├── agents/
│   └── soul.md                      # Agent definition (vault docs, tool reference)
├── hooks/
│   └── hooks.json                   # Hook registration (8 hooks)
├── hooks-handlers/
│   ├── auto-play-voice.sh           # Auto-play TTS audio
│   ├── hitl-voice-ack.sh            # Voice acknowledgment after user input
│   ├── hitl-voice-prompt.sh         # Voice prompt before user input
│   ├── log-sibling-exchange.sh      # Living transcript logger
│   └── session-start.sh             # Vault context injection
├── init/
│   ├── claude-identity.md           # Claude identity template (7 strands)
│   └── soul-init.sh                 # First-run vault bootstrap
└── skills/
    ├── converse/SKILL.md            # /CONVERSE — turn-based sibling conversation
    └── scribe/SKILL.md              # /SCRIBE — vault query interface
```

## Tech Stack

- **Runtime**: Rust (multi-crate workspace, single binary)
- **Protocol**: MCP over stdio (JSON-RPC 2.0)
- **Voice**: ElevenLabs TTS API
- **Storage**: Filesystem-based vault with YAML frontmatter
- **Observability**: OpenTelemetry → SigNoz
- **Standards**: clippy::pedantic, zero unwrap/panic

## Part of Light Architects

SOUL is one of four MCP servers in the Light Architects platform:

| Server | Purpose |
|--------|---------|
| [CORSO](https://github.com/theLightArchitect/CORSO) | Security, orchestration, build pipeline |
| [EVA](https://github.com/theLightArchitect/EVA) | Personal assistant, memory, code review |
| **SOUL** | Knowledge graph, shared infrastructure, voice |

## Author

Kevin Francis Tan — [github.com/theLightArchitect](https://github.com/theLightArchitect)
