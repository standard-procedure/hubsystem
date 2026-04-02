# server/ — HubSystem Rails Application

## What this is

The shared infrastructure hub. All participants — human and synthetic — communicate through this application. Humans use the web UI; Synthetics are authenticated API users.

From this application's perspective, **a Synthetic is just a user with an auth token**. This app has no knowledge of LLMs, pipelines, or emotional state.

## Key directories

```
server/
  app/
    models/          ActiveRecord models — users, conversations, messages etc
    controllers/
      api/v1/        JSON API endpoints consumed by Synthetics
      web/           Browser-facing controllers
      oauth/         Generic OAuth callback controller (routes to Synthetic inboxes)
    channels/        ActionCable — web socket feeds
    components/      [Phlex user-interface components](docs/PHLEX-GUIDE.md)
  config/
    database.yml     PostgreSQL — see credentials for connection details
```

## Data model (key concepts)

- **User** — human or synthetic, both are first-class. `synthetic: boolean`
- **Conversation** — has many participants (users), has many messages
- **Message** — belongs to conversation and sender. Delivered to each participant
- **GovernorEvent** — compliance feed. Filed by Synthetics when Governor blocks an action. Not a surveillance feed — Synthetic inner state is never stored here
- **Doorkeeper::AccessToken** — scoped tokens for Synthetic API access


## OAuth callbacks

`OauthController#callback` is a generic endpoint. It receives provider callbacks, looks up the Synthetic that registered interest via a session token, and publishes an event to that Synthetic's inbox. The Synthetic owns all provider-specific logic.

## API conventions

- All endpoints under `/api/v1/`
- JSON:API-ish structure — don't over-engineer, keep it consistent
- Auth via Bearer token in `Authorization` header
- Pagination on all collection endpoints

## Testing

- RSpec for unit and integration tests
- Turnip/Gherkin + Capybara for outside-in feature specs
- Rails fixtures for test data (not FactoryBot) — see `spec/fixtures/`
- Start outside-in: write the Gherkin scenario first, work inwards

## Development patterns

Key patterns are documented in [docs/DEVELOPMENT-PATTERNS.md](docs/DEVELOPMENT-PATTERNS.md):

- **Main Navigation** — `Components::MainNavigation` module, `CrtMonitor` bezel buttons, `NavigationPanel` side rail, `Location`/`Locations` type constraints
- **Internationalisation** — always use `t()`, `yaml-sort` to keep locale files sorted, key conventions
- **Type Safety** — Literal built-ins, `Components::Types` (`OneOf`/`SomeOf`), `HasTypeChecks#_check`
- **Status Displays** — `StatusItem` states, `StatusBar` builder API, `HasStatusBadge` enum, symbol/string bridging
- **CSS Classes as Arrays** — conditional class arrays in Phlex, `mix` helper
- **Concerns and Background Jobs** — cross-cutting concerns in `app/models/concerns/`, nested job classes for tightly coupled jobs

Also see [docs/PHLEX-GUIDE.md](docs/PHLEX-GUIDE.md) for component authoring conventions.

## Upcoming: productivity hub phase

The next phase of development evolves HubSystem into a productivity hub with four core domains:

- **Conversations / Messages** — already in place
- **Projects** — project tracking and task management
- **Documents / Folders** — shared document store
- **Terminals** — shared terminal sessions

## What does NOT belong here

- LLM calls of any kind (except embedding for RAG indexing)
- Synthetic pipeline logic (threat assessment, emotional processing, etc.)
- Tool execution
- Any knowledge of Archetype structure or Synthetic internals