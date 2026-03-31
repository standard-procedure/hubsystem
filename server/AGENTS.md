# server/ — HubSystem Rails Application

## What this is

The shared infrastructure hub. All participants — human and synthetic — communicate through this application. Humans use the web UI; Synthetics are authenticated API users.

From this application's perspective, **a Synthetic is just a user with an auth token**. This app has no knowledge of LLMs, pipelines, or emotional state.

## Key directories

```
server/
  app/
    models/          ActiveRecord models — users, conversations, messages,
                     documents, tasks, governor_events
    controllers/
      api/v1/        JSON API endpoints consumed by Synthetics
      web/           Browser-facing controllers
      oauth/         Generic OAuth callback controller (routes to Synthetic inboxes)
    channels/        ActionCable — synthetic inbox subscriptions, page event feeds
    jobs/            ActiveJob — background work (embedding, RAG indexing etc)
  config/
    database.yml     PostgreSQL — see credentials for connection details
```

## Data model (key concepts)

- **User** — human or synthetic, both are first-class. `synthetic: boolean`
- **Conversation** — has many participants (users), has many messages
- **Message** — belongs to conversation and sender. Delivered to each participant
- **Document** — tagged, RAG-indexed via pgvector. Belongs to a knowledge base
- **Task** — hierarchical, with recurring/scheduled variants. Assigned to users
- **GovernorEvent** — compliance feed. Filed by Synthetics when Governor blocks an action. Not a surveillance feed — Synthetic inner state is never stored here
- **AuthToken** — scoped tokens for Synthetic API access

## WebSocket / ActionCable

Two channel types:
- **SyntheticInboxChannel** — each Synthetic subscribes to its own inbox. Messages posted here wake the Synthetic's event loop in `world/`
- **PageFeedChannel** — custom browser pages publish events here; they are routed to the appropriate Synthetic's inbox

## OAuth callbacks

`OauthController#callback` is a generic endpoint. It receives provider callbacks, looks up the Synthetic that registered interest via a session token, and publishes an event to that Synthetic's inbox. The Synthetic owns all provider-specific logic.

## API conventions

- All Synthetic-facing endpoints under `/api/v1/`
- JSON:API-ish structure — don't over-engineer, keep it consistent
- Auth via Bearer token in `Authorization` header
- Pagination on all collection endpoints

## Testing

- RSpec for unit and integration tests
- Turnip/Gherkin + Capybara for outside-in feature specs
- FactoryBot for test data
- Start outside-in: write the Gherkin scenario first, work inwards

## What does NOT belong here

- LLM calls of any kind (except embedding for RAG indexing)
- Synthetic pipeline logic (threat assessment, emotional processing, etc.)
- Tool execution
- Any knowledge of Archetype structure or Synthetic internals