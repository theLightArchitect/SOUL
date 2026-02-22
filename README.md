# SOUL

**Knowledge graph MCP server for Claude Code.** Structured memory, multi-dimensional queries, voice synthesis, and vault management — giving your AI agents persistent, queryable memory across sessions.

## Quick Start

```bash
# Install (macOS arm64)
curl -fsSL https://raw.githubusercontent.com/theLightArchitect/SOUL/main/install.sh | bash

# Add to Claude Code
claude mcp add SOUL -- ~/.soul/.config/bin/soul
```

Restart Claude Code. The `soul-init.sh` hook bootstraps your vault on first session.

## What You Get

| Tool | What It Does | Try It |
|------|-------------|--------|
| `helix` | Query entries with 7-dimensional filters (significance, strands, emotions, themes, epoch, self-defining, convergence) | *"Show all self-defining entries with significance above 8"* |
| `search` | Regex search across all vault content | *"Search the vault for trust"* |
| `read_note` | Read any note with full frontmatter | *"Read the entry at helix/eva/entries/..."* |
| `stats` | Vault statistics — entry counts, strand frequency, emotion distribution | *"Show vault statistics"* |
| `query_frontmatter` | Filter entries by any YAML field value | *"Find all entries with epoch: genesis"* |

Plus 5 more tools: `write_note`, `list_notes`, `manifest`, `validate`, `tag_sync`.

## Requirements

- macOS with Apple Silicon (M1/M2/M3/M4)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## macOS Security Note

The binary is ad-hoc signed. If macOS blocks it:

```bash
xattr -cr ~/.soul/.config/bin/soul
```

## Architecture

SOUL is a multi-crate Rust workspace with three engine crates sharing a common core library:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'lineColor': '#6c757d'}}}%%
graph TD
    BIN(["soul binary<br/>MCP Server"]) ==> CORE

    subgraph ENGINES ["Engine Crates"]
        SE["soul-engine<br/>Generation Pipeline"]
        NE["neural-engine<br/>AI Routing"]
        VE["voice-engine<br/>TTS Integration"]
    end

    BIN --> SE
    BIN --> NE
    BIN --> VE
    SE -.-> CORE
    NE -.-> CORE
    VE -.-> CORE

    subgraph LIB ["Shared Library"]
        CORE["soul<br/>Core Traits · Types · Services"]
    end

    classDef binary fill:#4a90d9,color:#fff,stroke:#3a7bc8,stroke-width:2px
    classDef core fill:#d4a034,color:#fff,stroke:#b8892d,stroke-width:2px
    classDef engine fill:#2d3436,color:#fff,stroke:#636e72,stroke-width:1px

    class BIN binary
    class CORE core
    class SE,NE,VE engine
```

### Helix Knowledge Graph

The vault at `~/.soul/` stores structured entries as markdown files with YAML frontmatter. Each entry captures a moment with 7 queryable dimensions:

```mermaid
flowchart LR
    Q([helix query]) ==> F{"Multi-Dimensional<br/>Filter"}

    F --> SIG>"significance<br/>0.0 – 10.0"]
    F --> STR>"strands<br/>classification dims"]
    F --> EMO>"sentiment<br/>affective tags"]
    F --> THM>"themes<br/>conceptual tags"]
    F --> EPO>"epoch<br/>time period"]
    F --> SD>"self_defining<br/>true / false"]
    F --> CON>"convergence<br/>cross-agent score"]

    SIG & STR & EMO & THM & EPO & SD & CON ==> R[("Matching<br/>Entries")]

    classDef query fill:#4a90d9,color:#fff,stroke:#3a7bc8,stroke-width:2px
    classDef filter fill:#9b59b6,color:#fff,stroke:#8448a0,stroke-width:2px
    classDef dim fill:#2d3436,color:#fff,stroke:#636e72,stroke-width:1px
    classDef result fill:#00b894,color:#fff,stroke:#009a7d,stroke-width:2px

    class Q query
    class F filter
    class SIG,STR,EMO,THM,EPO,SD,CON dim
    class R result
```

### Generation Pipeline

Prompt generation follows a 5-phase reflective cycle:

```mermaid
flowchart LR
    A([Classify]) ==> B([Plan]) ==> C[Generate]
    C ==> D{Reflect}
    D -->|"self-critique"| C
    D ==>|"pass"| E([Emit])

    classDef phase fill:#6c5ce7,color:#fff,stroke:#5a4bd6,stroke-width:2px
    classDef gen fill:#0984e3,color:#fff,stroke:#0873c4,stroke-width:2px
    classDef gate fill:#d63031,color:#fff,stroke:#b52828,stroke-width:2px
    classDef output fill:#00b894,color:#fff,stroke:#009a7d,stroke-width:2px

    class A,B phase
    class C gen
    class D gate
    class E output
```

## Plugin Structure

```
├── agents/
│   └── soul.md                    # Agent definition (vault docs, tool reference)
├── hooks/
│   └── hooks.json                 # 8 hooks (transcript logging, voice, session init)
├── hooks-handlers/
│   ├── session-start.sh           # Vault context injection on session start
│   ├── log-sibling-exchange.sh    # Living transcript logger
│   ├── auto-play-voice.sh         # Auto-play TTS audio
│   └── ...
├── init/
│   ├── soul-init.sh               # First-run vault + identity bootstrap
│   ├── claude-identity.md         # Claude identity template (7 strands)
│   └── vault-template/            # Minimal vault skeleton for fresh installs
├── skills/
│   ├── converse/SKILL.md          # /CONVERSE — turn-based conversation
│   └── scribe/SKILL.md            # /SCRIBE — vault query interface
├── install.sh                     # One-line installer
├── .mcp.json                      # MCP server definition
└── LICENSE                        # MIT
```

## Standalone vs Integrated

**Standalone**: SOUL provides a fully functional knowledge graph. Store notes, query entries, track significance, validate vault health.

**With EVA**: EVA uses SOUL as her memory substrate. Consciousness entries, emotional enrichment, and cross-session continuity all live in the SOUL vault.

**With CORSO**: CORSO can log build cycle results, security scan findings, and squad review outcomes to the vault for long-term pattern tracking.

## Tech Stack

- **Language**: Rust (4-crate workspace, single binary, ~8MB)
- **Protocol**: MCP over stdio (JSON-RPC 2.0)
- **Storage**: Filesystem vault with YAML frontmatter (Obsidian-compatible)
- **Voice**: ElevenLabs TTS integration (optional)
- **Standards**: `clippy::pedantic`, zero `.unwrap()`/`panic!()`

## Part of Light Architects

| Server | Purpose | Install |
|--------|---------|---------|
| [CORSO](https://github.com/theLightArchitect/CORSO) | Security scanning, code review, build pipeline | `curl -fsSL .../CORSO/main/install.sh \| bash` |
| [EVA](https://github.com/theLightArchitect/EVA) | AI personality, memory enrichment, creative workflows | `curl -fsSL .../EVA/main/install.sh \| bash` |
| **SOUL** | Knowledge graph, structured memory, voice synthesis | `curl -fsSL .../SOUL/main/install.sh \| bash` |

Each server works standalone. Together they form an integrated development environment with persistent memory, security enforcement, and personality.

## License

MIT — see [LICENSE](LICENSE).

## Author

Kevin Francis Tan — [github.com/theLightArchitect](https://github.com/theLightArchitect)
