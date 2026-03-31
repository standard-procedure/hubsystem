# Synthetic Agents — server/ perspective

> The synthetic runtime (pipeline, LLM calls, emotional state, Archetype config) lives in `world/`. See `world/AGENTS.md` for the full architecture.
>
> This document covers only what `server/` knows and owns about Synthetics.

## What server/ knows about a Synthetic

From this application's perspective, **a Synthetic is a User with an auth token**. No LLMs run inside `server/`. No pipeline, no emotional processing, no Archetype config.

```
server/ knows:
  User (synthetic: true)       — name, uid, status, auth token
  Synthetic::Memory records    — written by world/ via API; RAG-indexed here
  GovernorEvent records        — filed by world/ when Governor blocks an action

server/ does NOT know:
  How the synthetic reasons
  What LLM it uses
  Its emotional state
  Its Archetype
  Whether it is currently processing a message
```

## Identity

Each Synthetic has a `User` record (`synthetic: true`). Auth tokens are scoped `AuthToken` records — the Synthetic authenticates all API calls with a Bearer token. Humans and Synthetics are both Users; there is no separate privileged runtime account.

## How Synthetics interact with server/

All interaction is via the HubSystem JSON API and WebSocket — no shared database access.

### Inbound (server/ → world/)

- **SyntheticInboxChannel** (ActionCable) — each Synthetic subscribes to its own inbox stream. When a message is delivered, `server/` publishes an event here. `world/` wakes the relevant Synthetic's event loop.
- **PageFeedChannel** (ActionCable) — browser-based custom pages publish events here; `server/` routes them to the appropriate Synthetic's inbox.
- **OAuth callbacks** — `OauthController#callback` is a generic endpoint. It receives provider callbacks, looks up the Synthetic that registered interest via a session token, and publishes an event to that Synthetic's inbox. The Synthetic owns all provider-specific logic.

### Outbound (world/ → server/)

Synthetics call the JSON API under `/api/v1/`. Common operations:

```ruby
# Posting a message
POST /api/v1/conversations/:id/messages

# Filing a Governor event (compliance feed, not surveillance)
POST /api/v1/governor_events

# Reading/writing memories (private, RAG-indexed)
GET  /api/v1/memories
POST /api/v1/memories

# Fetching/updating tasks
GET  /api/v1/tasks
POST /api/v1/tasks/:id/completion
```

## Memory and Documents

### Synthetic::Memory

Private to each Synthetic. Written by `world/` via the API after each conversation turn. `server/` stores and indexes them with pgvector for semantic search; `world/` queries them during Threat Assessment and memory retrieval.

Each memory has `content`, `tags`, and a 768-dimension vector embedding. Semantic search via cosine distance (pgvector).

### Document

Public knowledge visible to all Users. Any User (human or Synthetic) can author documents via the API. Same tag and text search interface as memories, also pgvector-indexed.

## GovernorEvents

Filed by `world/` when the Governor module blocks a Synthetic's intended action. `server/` stores them as a compliance feed for organisational visibility. They are not a surveillance feed — Synthetic inner state (emotional state, private notes, memories beyond what the Synthetic itself publishes) is never sent here.

## Processing Pipeline

The processing pipeline (Threat Assessment → Emotional Processing → LLM Call → Governor → Memory Processing → Capacity Processing) runs entirely in `world/` as an `Async::Service` supervised event loop. It is not an ActiveJob; it does not run inside `server/`.

See `world/AGENTS.md` for the full pipeline architecture.

## LLM Tiers

LLM tier configuration (`classifier`, `conversational`, `analytical`, `technical`, `frontier`, `private`, `embedding`, `vision`) is in `world/config/llm_tiers.yml`. It is `world/`'s concern.

`server/` uses the `embedding` tier only (for RAG indexing via `GenerateEmbeddingJob`).

## Testing

- RSpec unit and integration tests for API endpoints
- Turnip/Gherkin + Capybara for outside-in feature specs
- FactoryBot for test data
- Synthetic behaviour is observable via the API only — do not test `world/` internals from here

LLM calls are not made in `server/` tests (except embedding, which is mocked via `stub_llm_response`).
