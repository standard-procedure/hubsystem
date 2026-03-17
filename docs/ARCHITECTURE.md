# HubSystem Architecture

## Overview

HubSystem is a multi-user, multi-tenant AI agent harness. Inspired by the HubSystem/SecUnit relationship in the Murderbot Diaries — persistent, emotionally real agents with individual memory, security clearances, and a career arc.

See `../docs/design.md` (symlinked from `~/cher/docs/hub-system-design.md`) for the full design document.

## Mono-repo Structure

```
hubsystem/
├── AGENTS.md                  ← Agent guide (you are here)
├── CLAUDE.md                  ← Symlink to AGENTS.md
├── README.md                  ← Human-friendly overview
├── docs/
│   ├── ARCHITECTURE.md        ← This file
│   ├── IMPLEMENTATION-PLAN.md ← Phased build plan
│   └── design.md              ← Full design document
├── hubsystem-server/          ← Rails API server (Phase 1)
│   ├── README.md
│   ├── .devcontainer/         ← DevContainer with PostgreSQL
│   ├── app/
│   ├── spec/
│   └── ...
└── hubsystem-integration/     ← End-to-end integration suite (Phase 2+)
    ├── README.md
    └── spec/                  ← Starts Rails server, exercises CLI
```

## Core Concepts

### Participants (The Directory)

Every entity is a `Participant` — human, agent, monitor, timer, or output channel. All are first-class. You interact with any of them the same way: post a message to their inbox.

```
Participant (STI base)
├── HumanParticipant
├── AgentParticipant          ← has memory, emotional state, personality
├── MonitorParticipant        ← background watcher, posts alerts
├── TimerParticipant          ← scheduled task, posts messages
├── SlackChannelParticipant   ← output channel
├── DisplaySurfaceParticipant ← output channel
└── EmailParticipant          ← output channel
```

### Security Passes

Participants have security passes granting capabilities. Passes are scoped to groups (account/department/team). The Amygdala checks passes before processing messages.

### Messages

Multipart (MIME-style). A message has many `MessagePart`s, each with a `content_type` and optional `channel_hint`. Output channels pick the best matching part.

```
Message
├── from: Participant
├── to: Participant
├── conversation: Conversation (optional — nil = one-off)
└── parts: [MessagePart]
    ├── content_type: "text/markdown"
    │   channel_hint: "slack"
    └── content_type: "text/plain"
        channel_hint: nil
```

### Memory (Three Tiers)

All backed by pgvector embeddings in PostgreSQL:

1. **Personal memory** — unique to each agent instance
2. **Class memory** — shared across all agents of the same type
3. **Knowledge base** — org/account/department-scoped reference material

### The Neural Architecture (Trigger Pipeline)

Every message passes through a pipeline of modules:

```
Inbound:
  Amygdala (threat + auth) → Hippocampus (RAG) → Prefrontal Cortex (LLM turn)
  → Hippocampus (write memory) → Amygdala (update emotions) → Brainstem (exhaustion)

Outbound:
  Hippocampus (class memory promotion) → Message dispatched
```

### Emotional State

Each agent carries emotion parameters (happy, focused, irritated, anxious, exhausted) that update after every turn. They colour the system prompt dynamically and double as operational telemetry.

### Exhaustion / Sleep

Agents run forever. When exhaustion exceeds a threshold, the agent enters `napping` state — messages queue, background compaction runs, agent wakes refreshed. Communicated to callers as "I'm exhausted, try again in an hour."

## Tech Stack

- **Ruby on Rails** (API mode)
- **PostgreSQL** with pgvector (embeddings)
- **Async gem** (fiber-based concurrency — high I/O concurrency)
- **Falcon** (async-native Rack server)
- **RSpec** (unit + request specs)
- **DevContainer** (consistent dev environment)

## Key Design Principles

1. Everything is a Participant — no special-casing humans vs agents vs channels
2. Routing is messaging — output channels are in the directory
3. Security is pre-processing — Amygdala fires before the agent sees the content
4. Memory is layered and permission-scoped
5. Emotional state is both personality and telemetry
6. Integration tests live outside the Rails app
