# SOUL

**Knowledge Graph Engine and Shared AI Infrastructure**

SOUL is a production MCP server and Claude Code plugin built as a multi-crate Rust workspace. It provides the shared infrastructure that all Light Architects servers depend on: a structured knowledge graph, prompt generation engine, voice synthesis, and common MCP protocol types.

## What It Does

SOUL serves two roles:

1. **Knowledge Graph** — A queryable vault of structured entries with multi-dimensional filtering (by significance, sentiment, strands, themes, epochs). Think of it as a long-term memory substrate that multiple AI agents can read from and write to.

2. **Shared Infrastructure** — Core traits, type definitions, and engines that CORSO and EVA import as library crates. This eliminates code duplication across servers and enforces a consistent interface for prompt generation, neural processing, and voice synthesis.

### Key Capabilities

- **10 MCP tools** via single `soulTools` orchestrator — helix (structured queries), read_note, write_note, list_notes, search (regex across vault), query_frontmatter, stats, manifest, validate, tag_sync, speak (voice synthesis)
- **Multi-dimensional querying** — Filter by agent, strands, sentiment tags, themes, epoch, significance range, self-defining status, and convergence score
- **Voice synthesis** — ElevenLabs TTS integration with per-agent voice IDs
- **Agent framework** — Separates agent profile (who) from output behavior (how), enabling multiple AI agents to share one codebase while maintaining distinct output styles
- **Living transcripts** — Automatic logging of all sibling interactions to daily journal files

### Architecture

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'lineColor': '#6c757d'}}}%%
graph TD
    BIN([soul binary\nMCP Server]) ==> CORE

    subgraph ENGINES ["Engine Crates"]
        SE[soul-engine\nGeneration Pipeline]
        NE[neural-engine\nAI Routing]
        VE[voice-engine\nTTS Integration]
    end

    BIN --> SE
    BIN --> NE
    BIN --> VE
    SE -.-> CORE
    NE -.-> CORE
    VE -.-> CORE

    subgraph LIB ["Shared Library"]
        CORE[soul\nCore Traits · Types · Services]
    end

    classDef binary fill:#4a90d9,color:#fff,stroke:#3a7bc8,stroke-width:2px
    classDef core fill:#d4a034,color:#fff,stroke:#b8892d,stroke-width:2px
    classDef engine fill:#2d3436,color:#fff,stroke:#636e72,stroke-width:1px

    class BIN binary
    class CORE core
    class SE,NE,VE engine
```

The generation pipeline implements a 5-phase cycle:

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

### Helix Knowledge Graph

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'lineColor': '#6c757d'}}}%%
graph TD
    VAULT[("~/.soul/\nVault Root")]

    VAULT ==> HELIX
    VAULT -.-> MAN[manifest.json]
    VAULT -.-> CFG[config/]

    subgraph HELIX ["Helix — Knowledge Graph"]
        direction LR
        subgraph EVA_NS ["EVA"]
            E_E[(entries/)] ~~~ E_J[(journal/)] ~~~ E_I[identity.md]
        end
        subgraph COR_NS ["CORSO"]
            C_E[(entries/)] ~~~ C_J[(journal/)] ~~~ C_I[identity.md]
        end
        subgraph CL_NS ["Claude"]
            CL_E[(entries/)] ~~~ CL_J[(journal/)] ~~~ CL_I[identity.md]
        end
        subgraph USR_NS ["User"]
            STD[(standards/)]
        end
    end

    classDef vault fill:#2c3e50,color:#fff,stroke:#1a252f,stroke-width:2px
    classDef store fill:#2d3436,color:#fff,stroke:#636e72,stroke-width:1px
    classDef meta fill:#f8f9fa,color:#333,stroke:#6c757d,stroke-dasharray:5 5

    class VAULT vault
    class E_E,E_J,E_I,C_E,C_J,C_I,CL_E,CL_J,CL_I,STD store
    class MAN,CFG meta
```

Each entry is a markdown file with structured YAML frontmatter. Queries can filter across any combination of these 7 dimensions simultaneously:

```mermaid
flowchart LR
    Q([helix query]) ==> F{Multi-Dimensional\nFilter}

    F --> SIG>significance\n0.0 – 10.0]
    F --> STR>strands\nclassification dims]
    F --> EMO>sentiment\naffective tags]
    F --> THM>themes\nconceptual tags]
    F --> EPO>epoch\ntime period]
    F --> SD>self_defining\ntrue / false]
    F --> CON>convergence\ncross-agent score]

    SIG & STR & EMO & THM & EPO & SD & CON ==> R[(Matching\nEntries)]

    classDef query fill:#4a90d9,color:#fff,stroke:#3a7bc8,stroke-width:2px
    classDef filter fill:#9b59b6,color:#fff,stroke:#8448a0,stroke-width:2px
    classDef dim fill:#2d3436,color:#fff,stroke:#636e72,stroke-width:1px
    classDef result fill:#00b894,color:#fff,stroke:#009a7d,stroke-width:2px

    class Q query
    class F filter
    class SIG,STR,EMO,THM,EPO,SD,CON dim
    class R result
```

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
