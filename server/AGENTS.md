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

First, detect whether you are inside or outside the devcontainer:

```bash
test -d /workspaces && echo "INSIDE" || echo "OUTSIDE"
```

```bash
# Inside devcontainer — run commands directly:
bin/rspec spec/

# Outside devcontainer — start the container, then exec into it:
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash -lc "bin/rspec spec/"
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

## Testing

### Fixtures and Embeddings

Tests use Rails fixtures (not factories). Fixture files are in `spec/fixtures/`.

- `synthetic_memories.yml` and `documents.yml` include pre-computed 768-dimension embeddings from `nomic-embed-text` via Ollama. This allows semantic search (pgvector nearest_neighbors) to work in tests without a running Ollama instance.
- When adding new fixture records that need embeddings, generate them inside the devcontainer:
  ```ruby
  RubyLLM.embed("your text", model: "nomic-embed-text", provider: :openai, assume_model_exists: true).vectors
  ```
- For fixtures with non-standard table names (e.g. `synthetic_memories.yml`), use `_fixture: model_class:` at the top of the file so Rails can resolve associations correctly.
- User fixtures require `role_type` and `role_id` (delegated type). Use `<%= ActiveRecord::FixtureSet.identify(:fixture_name) %>` for `role_id`. Corresponding role fixtures live in `humans.yml` and `synthetics.yml`.
- Specs tagged `:llm` hit real Ollama and are excluded by default. Run them with: `bin/rspec --tag llm`

### Web UI Testing Principle

Always write web UI tests assuming JavaScript is unavailable. Use Rack::Test (request specs) which is fast and avoids timing issues. The actual implementation may use JS (turbo-frames, broadcasts) but tests should work without it:

- Links open new pages in tests but may open within turbo-frames in a real browser
- For turbo-broadcasts, reload the page to check updates
- Playwright is a last resort — ask for advice before using it
- If a scenario proves difficult without JS, we'll devise patterns for common Turbo scenarios

### Ollama Models

RubyLLM doesn't have `nomic-embed-text` in its built-in registry. Use `assume_model_exists: true` and `provider: :openai` when calling `RubyLLM.embed` with Ollama models. Model tiers are configured in `config/llm_models.yml`.

## Synthetic Agents

Synthetics are persistent AI entities with identity, emotion, and memory. See [`docs/SYNTHETIC-AGENTS.md`](docs/SYNTHETIC-AGENTS.md) for the full architecture — processing pipeline, emotional state, LLM context, memory system, and testing approach.

---

**For complete development standards**, see the full AGENTS.md at the application root.
