# hubsystem-integration

External HTTP integration test suite for the HubSystem Rails API.

## What this is

This suite lives **outside** the Rails application. It drives `hubsystem-server` via real HTTP requests — no Rails internals, no ActiveRecord, no shared process. It exists to verify the full stack works end-to-end:

- Participants can be listed and messaged
- Authentication via `X-Hub-Token` is enforced
- Conversations are created and access-controlled
- The agent pipeline runs (memories are written, emotions update, replies are delivered)

## Prerequisites

- Ruby 3.x and Bundler
- PostgreSQL running (same instance used by `hubsystem-server`)
- `hubsystem-server` dependencies installed (`cd hubsystem-server && bundle install`)

## Running

```bash
cd hubsystem-integration
bundle install
bundle exec rspec
```

The suite starts a Rails server on port **3737** using the `integration` environment, resets the integration database (`hubsystem_server_integration`), seeds it with known data, runs all specs, then shuts the server down.

The database is kept separate from the unit-test database (`hubsystem_server_test`) so both suites can run safely.

## How it works

### Server lifecycle

`spec/support/server_manager.rb` handles:
1. `db:reset` on `RAILS_ENV=integration` — clean schema + seed data
2. `rails server -p 3737` in the background
3. Waits for `/up` health check before starting specs
4. Sends `SIGTERM` after the suite finishes

### Seed data

`hubsystem-server/db/seeds/integration.rb` creates:
- **Baz** — a `HumanParticipant` with a token written to `/tmp/hubsystem-integration-baz-token`
- **Aria** — an `AgentParticipant`
- A `Group` and `SecurityPass` records granting both "message" capability

### API client

`spec/support/api_client.rb` wraps Faraday for JSON HTTP requests with optional `X-Hub-Token` auth.

## Spec files

| File | Covers |
|------|--------|
| `participants_spec.rb` | `GET /participants` |
| `messages_spec.rb` | `POST` and `GET /participants/:id/messages`, auth enforcement |
| `conversations_spec.rb` | `POST /conversations`, `GET /conversations/:id/messages`, member-only access |
| `pipeline_spec.rb` | Full pipeline: message → agent reply → emotion update → memory write |

## Notes

- LLM calls use stubs in `integration` environment — no API keys required.
- Server logs go to `/tmp/hubsystem-integration-server.log`.
