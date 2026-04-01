# Synthetic Agents — server/ perspective

> The synthetic runtime lives in `world/`. See `world/AGENTS.md` for the full architecture.
>
> This document covers only what `server/` knows and owns about Synthetics.

## What server/ knows about a Synthetic

From this application's perspective, **a Synthetic is just another User**. No LLMs run inside `server/`. No pipeline, no emotional processing, no memories or tool calls.

```
server/ knows:
  User details - name, photo etc
  User status - badge colour, badge message
  GovernorEvent records — filed by world/ when Governor blocks an action

server/ does NOT know:
  How the synthetic reasons
  What LLM it uses
  Its emotional state
  Whether it is currently processing a message
```

The User Status Badge can be used by both humans and synthetics to broadcast their current state to other users.  The badge consists of an enum and a message - the enum is then represented on-screen as a colour.  The `world/` automatically updates the status badge of synthetics as they move through different states (offline = sleeping, online = available, info = busy, warning = fatigued, critical = overly emotional or error condition) - this is not for surveillance purposes, just automating the use of the status badge (for example, busy or fatigued could mean "do not disturb").

## Identity

Each Synthetic has a `User` record. Auth tokens are scoped `Doorkeeper::OauthAccessToken` records — the Synthetic authenticates all API calls with a Bearer token. Humans and Synthetics are both Users; there is no separate privileged runtime account.

## How Synthetics interact with server/

All interaction is via the HubSystem JSON API and/or WebSocket — no shared database access.

### Inbound (server/ → world/)

- Reading from the JSON API
- Subscribing to web socket feeds

### Outbound (world/ → server/)

- Writing to the JSON API
- Writing to web socket feeds

## GovernorEvents

Filed by `world/` when the Governor module blocks a Synthetic's intended action. `server/` stores them as a compliance feed for organisational visibility. They are not a surveillance feed — Synthetic inner state (emotional state, private notes, memories beyond what the Synthetic itself publishes) is never sent here.

## Testing

- RSpec unit and integration tests for API endpoints
- Turnip/Gherkin + Capybara for outside-in feature specs
- Rails fixtures for test data (loaded at the start of the test run, then rolled back via transaction after each individual example - very fast)
- Synthetic behaviour is observable via the API only — do not test `world/` internals from here

LLM calls are not made in `server/` tests
