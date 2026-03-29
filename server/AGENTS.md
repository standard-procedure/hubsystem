# hubsystem-server — Agent Guide

This is the Rails API server for HubSystem.

**Parent project:** See `../AGENTS.md` for overall HubSystem architecture and design.

## Development Principles

This project follows strict test-driven development with dual web/API feature parity.

See `docs/DEVELOPMENT-PROCESS.md`

## Technology Stack

- **Backend:** Rails 8+, Ruby 3.4.5, PostgreSQL with pgvector
- **Frontend:** Phlex components, Hotwire, Tailwind CSS
- **JS Runtime:** Bun
- **Testing:** RSpec, Turnip, Playwright, Fixtures
- **Linting:** StandardRB
- **Type Safety:** Literal
- **Notifications:** Noticed (event-sourced)
- **Monitoring:** RailsPulse
- **API Docs:** rspec-openapi (auto-generated)

## User Interface 

The design system is called [mother](../docs/hubsystem-design-system-reference.html) implemented in `app/assets/mother.css`.  It is designed to look like the computers from the 1980s Aliens films.  

## Phlex Components

This project uses **Phlex** (not ERB) for all HTML rendering. See [`docs/PHLEX-GUIDE.md`](docs/PHLEX-GUIDE.md) for the full guide covering components, views, layouts, attributes, yielding, kits, Literal properties, testing, and Rails integration.

## HubSystem-Specific Concepts

See `../docs/ARCHITECTURE.md` for full design.

## Development Environment

This project uses a devcontainer with Docker Compose sidecars for PostgreSQL (with pgvector), a bash sandbox, and Ollama (local LLM).

### Running commands

Check if you are inside or outside the devcontainer:

```bash
# Inside devcontainer (test -d /workspaces):
bin/rspec spec/

# Outside devcontainer:
devcontainer exec --workspace-folder ~/Developer/hubsystem/server bash -lc "bin/rspec spec/"
```

### Services

| Service | Port | Purpose |
|---------|------|---------|
| postgres | 5432 | Database (pgvector enabled) |
| sandbox | — | Shared bash execution for synthetics |
| ollama | 11434 | Local LLM inference (qwen2.5:3b, nomic-embed-text) |

### Environment variables

Set in `.devcontainer/devcontainer.env` (gitignored):
- `ANTHROPIC_API_KEY` — for Claude models (medium/high tier)
- `DB_HOST` — auto-set to `postgres` inside devcontainer

## Synthetic Agents

Synthetics are persistent AI entities with identity, emotion, and memory. See [`docs/SYNTHETIC-AGENTS.md`](docs/SYNTHETIC-AGENTS.md) for the full architecture — processing pipeline, emotional state, LLM context, memory system, and testing approach.

---

**For complete development standards**, see the full AGENTS.md at the application root.
