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
  - `ruby_llm` (one API for OpenAI, Anthropic, Gemini, Ollama, OpenRouter etc. — model swappable per role via config)
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

## Phase 2.5 — Memory Upgrades + RubyLLM

### 2.5.1 Migrate to RubyLLM

- Add `ruby_llm` gem
- Replace stub LLM/embedding providers in Amygdala, Hippocampus, PrefrontalCortex with RubyLLM calls
- Add `config/initializers/ruby_llm.rb` — loads API keys from ENV vars:

```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.openai_api_key    = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.ollama_api_base   = ENV.fetch("OLLAMA_API_BASE", "http://localhost:11434")
end
```

- Add `config/models.yml` — per-role model mapping, environment-aware, version-controlled:

```yaml
# config/models.yml
default: &default
  security_eval:     gpt-5.4-nano
  emotion_eval:      gpt-5.4-nano
  path_generation:   gpt-5.4-nano
  main_turn:         claude-sonnet-4-6
  class_memory_eval: gpt-5.4-nano
  embedding:         text-embedding-3-small

development:
  <<: *default

test:
  <<: *default
  # Override to stubs in test — no real model names needed,
  # LLMProvider will use stub provider when RAILS_ENV=test
  security_eval:     stub
  emotion_eval:      stub
  path_generation:   stub
  main_turn:         stub
  class_memory_eval: stub
  embedding:         stub

production:
  <<: *default
  main_turn:         claude-opus-4-6   # Upgrade for production if needed
```

- Load via: `Rails.application.config_for(:models)` returns a hash for the current environment
- `LLMProvider.for_role(:security_eval)` reads from this config, returns a RubyLLM client (or stub in test)
- Tests use stub provider — no network calls, no ENV vars required

### 2.5.2 Tiered Memory Content (L0/L1/L2)

Update Memory model:
- Add `summary:string` (one line — L0, always in system prompt)
- Add `excerpt:text` (paragraph — L1, in conversation context each turn)
- `content:text` is L2 (already exists — full text, loaded on demand)
- Embed `excerpt` rather than `content`
- Migration + update MemoryWriter to populate all three tiers (cheapest LLM call to generate summary + excerpt from content)

Update Hippocampus retrieval:
- `retrieve(... tier: :l0)` → returns summaries only (for system prompt)
- `retrieve(... tier: :l1)` → returns excerpts (for turn context)
- `retrieve(... tier: :l2)` → returns full content (on demand)
- Default: L1

Update PrefrontalCortex::TurnProcessor:
- System prompt includes L0 summaries (always)
- Turn context includes L1 excerpts (RAG retrieved)
- L2 only fetched if agent explicitly requests full record

### 2.5.3 Memory Paths

Add `paths:string[]` to Memory with GIN index migration.

Update MemoryWriter:
- Auto-generate paths via `LLMProvider.for_role(:path_generation)` — cheap Nano call
- Always add date path: `["#{Date.today.strftime('%Y/%m/%d')}"]`
- Extract participant names and project names from context

Update Hippocampus::MemoryRetriever:
- Add `paths:` filter parameter
- `WHERE paths @> '{...}'` containment query (fast GIN lookup)
- Hybrid mode: path filter first, then cosine similarity on results

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

## Phase 4 — Seeds + Dart CLI (Playable Milestone 🎮)

Goal: something you can actually play with. Seeds populate the directory with named agents and a human (you). The Dart CLI lets you send messages, read your inbox, and have conversations — all from the terminal.

### 4.1 Seeds (hubsystem-server/db/seeds/development.rb)

- 5-8 named AgentParticipants using Faker for names/personalities (add `faker` gem)
- e.g. Aria (SupportAgent), Rex (SecurityAgent), Nova (ResearchAgent)
- One HumanParticipant for Baz with a known token (printed to stdout on seed)
- A default Group + SecurityPasses so everyone can message everyone
- `db/seeds.rb` routes to `seeds/#{Rails.env}.rb`

### 4.2 Dart CLI project (hubsystem-cli/)

```
hubsystem/
└── hubsystem-cli/
    ├── pubspec.yaml
    ├── bin/
    │   └── hubsystem.dart       ← entry point
    └── lib/
        ├── api_client.dart      ← reusable in Flutter later
        └── commands/
            ├── participants.dart
            ├── send_message.dart
            ├── inbox.dart
            └── conversation.dart
```

**Auth:** `HUBSYSTEM_TOKEN` env var — same for humans and agents:
```bash
export HUBSYSTEM_TOKEN=abc123   # humans set this in their shell
# Rails app sets it before spawning agent bash sandboxes
```

**Server URL:** `HUBSYSTEM_URL` env var (default: `http://localhost:3000`)

**Commands:**
```bash
hubsystem participants                          # list the directory
hubsystem send --to=aria --message="Hello"     # post a message
hubsystem inbox                                # read your inbox
hubsystem convo --with=aria --subject="Hi"     # start a conversation
hubsystem convo --id=42                        # read a conversation thread
```

**Build to a binary:**
```bash
dart compile exe bin/hubsystem.dart -o hubsystem
```

### 4.3 Agent workspaces

Each agent gets a persistent workspace directory on the host:

```
~/hubsystem-workspaces/
  aria/          ← Aria's persistent sandbox
    scripts/
    data/
  rex/
    scripts/
```

- Created on first use (when agent is seeded or first spawned)
- Bind-mounted read-write into bash sandbox containers
- Everything else in the container is read-only or absent
- `HUBSYSTEM_TOKEN` passed as env var by Rails before spawning — not stored in workspace files

### 4.4 Bash tool + sandbox (BashSandbox)

```ruby
class BashSandbox
  WORKSPACE_ROOT = ENV.fetch("HUBSYSTEM_WORKSPACE_ROOT", 
                             Rails.root.join("../hubsystem-workspaces").to_s)

  def self.run(command, agent:, timeout: 30)
    workspace = File.join(WORKSPACE_ROOT, agent.slug)
    FileUtils.mkdir_p(workspace)

    # Docker run: mount only agent workspace, no network to DB host
    result = system(
      "docker run --rm",
      "--network=hubsystem-sandbox",         # isolated network (no DB access)
      "-v #{workspace}:/workspace:rw",       # agent's persistent workspace
      "-w /workspace",
      "-e HUBSYSTEM_TOKEN=#{agent.token}",   # auth as the agent
      "-e HUBSYSTEM_URL=#{hubsystem_url}",
      "--memory=256m --cpus=0.5",
      "--timeout=#{timeout}",
      "hubsystem-sandbox:latest",            # minimal image: bash, ruby, dart CLI
      "bash", "-c", command
    )
    result
  end
end
```

The `hubsystem-sandbox` Docker image contains: bash, curl, the compiled hubsystem CLI binary. Nothing else. No psql, no ssh, no wget.

### Tools available to agents

| Tool | Ruby class | Notes |
|------|-----------|-------|
| `send_message` | `Tools::SendMessage` | Calls messaging API |
| `list_participants` | `Tools::ListParticipants` | Directory lookup |
| `read_inbox` | `Tools::ReadInbox` | Own inbox only |
| `start_conversation` | `Tools::StartConversation` | Open a thread |
| `subscribe_monitor` | `Tools::SubscribeMonitor` | Register for alerts |
| `unsubscribe_monitor` | `Tools::UnsubscribeMonitor` | De-register |
| `start_timer` | `Tools::StartTimer` | Schedule recurring message |
| `stop_timer` | `Tools::StopTimer` | Cancel timer |
| `bash` | `Tools::Bash` | Sandboxed shell (requires `"bash"` SecurityPass capability) |
| `search_memory` | `Tools::SearchMemory` | Explicit RAG query |
| `write_memory` | `Tools::WriteMemory` | Explicitly persist a memory |
| `read_memory` | `Tools::ReadMemory` | L2 full-content retrieval by ID |

Each tool checks the agent's SecurityPasses before executing. `bash` requires `"bash"` capability — a low-trust agent can exist without it.

---

## Phase 5 — "Flip the Switch" (Real LLM)

- Add real API keys to `.env`
- Personalities, emotional state, and memory start accumulating
- Agents write scripts in their workspaces
- Agents can modify their own tools via bash

---

## Phase 6 — Monitors, Timers, Output Channels

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
