# HubSystem — Guide for Agents

This repository contains two separate applications that together form HubSystem: a multi-user collaboration platform where participants are human or synthetic (AI).

## Repository Structure

```
hubsystem/
  server/    Rails application — the hub (conversations, API, knowledge base)
  world/     Ruby/Async application — the synthetic runtime
  CLAUDE.md  this file
```

**The two applications communicate exclusively via HTTP/WebSocket. They share no database and no process space.** Do not introduce direct dependencies between them.

## server/

See `server/CLAUDE.md` for full details.

The Rails hub application. Humans use the web UI. Synthetics use the JSON API. Key concerns: conversations, messages, shared knowledge base (pgvector RAG), task database, auth tokens, Governor event log, WebSocket publishing feed.

**Never add synthetic runtime logic here.** The Rails app has no knowledge of how a Synthetic works internally.

## world/

See `world/CLAUDE.md` for full details.

The synthetic runtime. A minimal Rails environment (no web server, no routes, no views) running long-lived Synthetic processes supervised by `async-service`. Synthetics communicate with `server/` exclusively via the HubSystem JSON API and WebSocket.

**Never add web-serving, routing, or view logic here.**

## Ideas and Notes

`docs/IDEAS.md` — scratch pad for ideas and things to revisit. Add entries there rather than letting them get lost.

## Shared Conventions

- Ruby version: managed by mise, see `.ruby-version`
- Tests: RSpec throughout, Turnip/Gherkin + Capybara for outside-in in `server/`
- Development: devcontainer-based workflow
- Outside-in BDD: start from the user's perspective, work inwards
- YAGNI: resist adding complexity until it is needed