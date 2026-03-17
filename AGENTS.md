# HubSystem — Agent Guide

> Start here if you're an LLM agent working on this project.

## What is HubSystem?

HubSystem is a multi-user, multi-tenant AI agent harness built in Ruby on Rails. Inspired by the HubSystem/SecUnit relationship in the Murderbot Diaries — persistent, emotionally real agents with individual memory, security clearances, and a career arc.

Agents are not stateless functions. They are persistent individuals with identity, memory, emotional state, and opinions about the people they work with.

## Mono-repo Structure

```
hubsystem/
├── AGENTS.md                  ← YOU ARE HERE
├── CLAUDE.md                  ← Symlink to this file
├── README.md
├── docs/
│   ├── ARCHITECTURE.md        ← Full system design
│   ├── IMPLEMENTATION-PLAN.md ← Phased build plan (read before starting work)
│   └── design.md              ← Original design document
└── hubsystem-server/          ← Rails API server (Phase 1 — current)
```

## Quick Orientation

| Task | Read |
|------|------|
| Understand the overall design | `docs/ARCHITECTURE.md` |
| Know what to build next | `docs/IMPLEMENTATION-PLAN.md` |
| Work on the Rails server | `hubsystem-server/README.md` |

## Key Concepts

- **Participants** — every entity (human, agent, monitor, timer, output channel) is a `Participant`. All are first-class. Same inbox/outbox protocol for all.
- **Security Passes** — grant capabilities, scoped to groups. Checked by the Amygdala before processing.
- **Messages** — multipart (MIME-style). Multiple `MessagePart`s per message, each with a `content_type` and optional `channel_hint`.
- **Memory** — three tiers: personal (per-agent), class (shared by agent type), knowledge base (org-scoped). All pgvector embeddings.
- **Neural Architecture** — the trigger pipeline: Amygdala (threat + auth + emotion) → Hippocampus (RAG) → Prefrontal Cortex (LLM) → Hippocampus (write) → Brainstem (exhaustion).
- **Emotional State** — jsonb column on agents: `{ happy: 75, focused: 80, irritated: 22 }`. Updates every turn. Colours system prompt. Also operational telemetry.

## Development Standards

- **Test-first, outside-in** — write failing specs before implementation
- **RSpec** throughout
- **Small focused commits** — one logical change per commit
- **Run specs before committing**: `bin/rspec`
- **Rails API mode** — no views, no asset pipeline
- **Async/Falcon** — fiber-based concurrency; use `Async` for I/O-bound work

## Current Phase

**Phase 1 — Rails Server Foundation**

See `docs/IMPLEMENTATION-PLAN.md` Phase 1 for the full task list.

TL;DR: create `hubsystem-server/` Rails API app, devcontainer with PostgreSQL + pgvector, core data model, basic messaging API, all with passing specs.
