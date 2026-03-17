# HubSystem Implementation Plan

## Phase 1 — Rails Server Foundation

Goal: a working Rails API server with the core data model, devcontainer, and passing specs.

### 1.1 Rails Project Setup

- Create `hubsystem-server/` as a new Rails API app (no asset pipeline)
- Add to mono-repo root `Gemfile` (or use workspace gemfile pattern)
- Configure `hubsystem-server/.devcontainer/` with:
  - Rails app container
  - PostgreSQL container (with pgvector extension)
  - Appropriate ports (3000 for Rails)
- Key gems:
  - `async` + `falcon` (async-native server)
  - `pgvector` (vector embeddings)
  - `devise` or session auth (TBD)
  - `pundit` or custom (for security pass evaluation)
  - `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`

### 1.2 Core Data Model

Implement and spec:

- `Participant` (STI base) with inbox/outbox associations
  - `HumanParticipant`
  - `AgentParticipant` (emotional state jsonb, agent_class, state machine)
  - `MonitorParticipant`
  - `TimerParticipant`
  - `SlackChannelParticipant`
  - `DisplaySurfaceParticipant`
  - `EmailParticipant`
- `SecurityPass` (join: participant → group + capability)
- `Group` (account/department/team scoping)
- `Conversation` (with participants through `ConversationMembership`)
- `Message` (from, to, conversation optional)
- `MessagePart` (content_type, channel_hint, body)
- `Memory` (participant, scope: personal/class/knowledge_base, embedding vector)

### 1.3 Participant Messaging API

Basic REST endpoints:
- `POST /participants/:id/messages` — post a message to a participant's inbox
- `GET /participants/:id/messages` — read inbox/outbox
- `POST /conversations` — start a conversation
- `GET /conversations/:id/messages` — conversation thread

### 1.4 DevContainer

`.devcontainer/devcontainer.json` + `compose.yaml`:
- Rails app service (Ruby + bundler)
- PostgreSQL 16 with pgvector extension enabled
- Automatic `db:prepare` on container start
- Port 3000 forwarded

---

## Phase 2 — The Neural Architecture

Goal: trigger pipeline wired up, Amygdala doing basic threat detection, Hippocampus doing memory read/write.

### 2.1 Amygdala

- `Amygdala::ThreatEvaluator` — calls Haiku, returns `:safe / :dodgy / :do_not_process`
- `Amygdala::AuthorisationChecker` — evaluates sender's security passes
- `Amygdala::EmotionUpdater` — adjusts agent emotion parameters after a turn
- Run threat + auth in parallel (Async)

### 2.2 Hippocampus

- `Hippocampus::MemoryRetriever` — RAG lookup (pgvector similarity search, scoped by security passes)
- `Hippocampus::MemoryWriter` — persist new memories with embeddings
- `Hippocampus::ClassMemoryPromoter` — promote personal memories to class memory (confidence threshold)

### 2.3 Brainstem / RAS

- `Brainstem::ExhaustionMonitor` — tracks fatigue, triggers nap state
- `Brainstem::ReticulaActivatingSystem` — manages agent wake/sleep state, queues messages during naps

### 2.4 Prefrontal Cortex

- `PrefrontalCortex::TurnProcessor` — assembles context, calls LLM, returns response
- Context assembly: personality prompt + emotional state + RAG memories + conversation history

---

## Phase 3 — Integration Test Suite

Goal: end-to-end specs that live outside the Rails app.

Location: `hubsystem-integration/`

- Starts the Rails server in test mode
- Sets up a clean database
- Exercises the full pipeline via HTTP:
  - Create participants
  - Post messages
  - Assert responses, emotional state changes, memory writes
- Framework: RSpec + `net/http` or `faraday`

---

## Phase 4 — Monitors, Timers, Output Channels

- `MonitorParticipant` with schedule + trigger condition
- `TimerParticipant` with cron-style schedule
- Output channel delivery (Slack, email, display surface)
- Streaming message parts (Action Cable / Async streams)

---

## Agent Workflow

When working on this project:

1. Read `AGENTS.md` for orientation
2. Read `docs/ARCHITECTURE.md` for design
3. Read this file for current phase + tasks
4. Work test-first (RSpec, outside-in)
5. Run specs before committing: `bin/rspec`
6. Commit small and often with descriptive messages
