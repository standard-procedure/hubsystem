# HubSystem — Architecture Summary (Revised)

*Updated March 2026 — mono-repo structure, Async::Service supervision*

---

## Repository Structure

HubSystem is a mono-repo containing two distinct applications that communicate exclusively via HTTP/WebSocket. They share no database, no process space, and no gem dependencies beyond standard libraries.

```
hubsystem/
  server/    # Rails application — the hub
  world/     # Ruby/Async application — where Synthetics live
```

---

## server/ — HubSystem Rails Application

The hub is a conventional Rails application. It is the shared infrastructure that all participants — human and synthetic — use to communicate.

**What it owns:**
- Conversations and messages (Slack-like UI for humans, JSON API for Synthetics)
- Shared knowledge base (RAG-indexed documents via pgvector)
- Hierarchical task database (recurring and scheduled tasks)
- User accounts and auth tokens (humans and Synthetics are both users)
- Governor event log — compliance feed, not surveillance
- OAuth callback handling (generic endpoint routing callbacks to Synthetic inboxes)
- WebSocket publishing feed (Synthetics subscribe to their inbox; custom pages publish events)

**Stack:** Rails, PostgreSQL, pgvector, RubyLLM (for hub-side embedding), Puma

**What it does not own:** Any knowledge of how a Synthetic works internally. From the Rails app's perspective, a Synthetic is an authenticated API user.

---

## world/ — Synthetic Runtime

A minimal Rails application (no web server, no routes, no views) that provides the Rails environment — `Rails.application`, credentials, ActiveRecord, RubyLLM persistence — without the web stack. Entry point is a long-running `async-service` process, not Puma.

**Why minimal Rails rather than plain Ruby:** RubyLLM uses Rails model persistence for LLM context messages. ActiveRecord outside Rails causes implicit dependency failures (MessageVerifier, Rails.env, secrets). A bare `Rails::Application` that requires only `active_record` and `ruby_llm` satisfies all dependencies cleanly.

**Stack:** Rails (no web stack), RubyLLM, Async gem, Async::Service, SQLite (per-Synthetic), async-service for supervision

---

## Supervision: Async::Service

The `world/` process is an `async-service` configuration file. Each Synthetic runs as a supervised service:

```ruby
#!/usr/bin/env async-service

service "sid-security-consultant" do
  service_class SyntheticService
  synthetic_id 17
  archetype "SecurityConsultant"
end
```

`container.run(count: 1, restart: true)` provides automatic restart on crash. The service file is the deployment manifest — adding a Synthetic to an organisation means adding a service declaration.

Multiple Synthetics share a container process as cooperative Async fibers. Distribution across containers is a scaling decision, not an architectural one.

---

## Synthetic Structure

Each Synthetic is an instance of an **Archetype** (the "model" in the physical robot sense — avoided to prevent confusion with LLM models). The Archetype defines:

- Operating system prompt ("You are a security consultant whose main priority is system integrity")
- Governor prompt (role-appropriate professional constraints)
- Skill access (which knowledge base sections are available)
- LLM tier assignments (which model tier to use for which processing stage)

### The Event Loop

```ruby
loop do
  process_pending_messages    # from WebSocket inbox
  check_recurring_tasks       # heartbeat / cron
  evaluate_emotional_state    # drift over time
  maybe_sleep_and_compact     # context management

  wait_for_event(timeout: heartbeat_interval)
end
```

The Synthetic is *present* and *listening*, not repeatedly summoned. Between messages it is idle, not non-existent.

### Processing Pipeline (cognitively inspired)

```
Incoming message
  → Threat Assessment        (amygdala — fast danger classification)
  → Emotional Processing     (am I fed up with this person?)
  → LLM Call                 (PFC — reasoning, response, tool calls)
  → Governor Module          (professional conscience — fires GovernorEvent if blocked)
  → Memory Processing        (hippocampus — update memories and notes)
  → Secondary Emotional      (has this made me feel better or worse?)
  → Capacity Processing      (reticular system — am I tired, do I need to sleep?)
```

### Resource Model: Nested Semaphores

Synthetics run inside an `Async::Semaphore` that caps their share of container cycles. Tools spawned by a Synthetic are nested inside a further semaphore carved from the Synthetic's own budget:

```
Container semaphore  (total available cycles)
  └── Sid's semaphore
        └── event loop
              └── run_tool(semaphore: 2)
                    ├── XeroTool instance 1
                    └── XeroTool instance 2
```

This makes Tools an intrinsic cost to the Synthetic — spawning many Tools degrades the Synthetic's own responsiveness. The disincentive is emergent from the architecture, not enforced by the Governor.

The same logic disincentivises long-running bash scripts: a blocking bash call ties up one of the Synthetic's fibers, slowing its inbox processing, increasing capacity pressure, and affecting emotional state. Synthetics are naturally incentivised to write proper async Tools.

---

## Tools vs Synthetics

| | Synthetic | Tool |
|---|---|---|
| Backed by | LLM | Ruby code |
| Behaviour | Emergent | Deterministic |
| Lifespan | Persistent | Ephemeral (TTL) |
| Pipeline | Full cognitive pipeline | Fixed input/output protocol |
| Spawned by | Archetype deployment | LLM tool-call: `run_tool(script:, concurrency:, input:)` |
| Cost | Semaphore share | Nested semaphore, carved from owner's budget |

A Tool is an LLM tool-call in Sid's agentic loop — `run_tool(script: "~/sid/harrys_xero_page.rb", concurrency: 2, input: "...")`. Sid decides to spawn it, pays for it with its own cycles, and remains accountable for it.

---

## LLM Tier Configuration

Semantic tiers rather than low/medium/high. Each Archetype specifies which tiers it uses:

```yaml
classifier:      # qwen2.5:3b   — threat assessment, intent, routing
conversational:  # kimi-k2.5    — always-on general interaction
analytical:      # glm-5        — research, planning, synthesis
technical:       # claude-sonnet — code, architecture, debugging
frontier:        # claude-opus   — novel/high-stakes problems
private:         # mistral:7b   — sensitive data, never leaves machine
embedding:       # nomic-embed-text — RAG, memory search
vision:          # kimi-k2.5    — screenshots, OCR, UI
```

---

## Memory and Emotional State

### Emotional state
Numeric values per emotion. System prompt instructs the Synthetic to colour responses accordingly. Private to the Synthetic — not exposed to HubSystem administrators directly.

### Memories
All memories carry:
```ruby
{ content: "...", emotional_impact: 89, emotional_valence: :negative }
```
Retrieval is weighted by semantic similarity, emotional impact, recency, and retrieval frequency. High-impact memories survive sleep compaction; low-impact memories are summarised away.

### Private notes
Relationship notes about other users ("Alice keeps asking me to disable the firewall"). Retrieved during Threat Assessment to prime the Synthetic before the LLM call.

### Sleep / compaction
When context window pressure reaches threshold, the Synthetic sleeps: old messages are examined, key facts extracted to memory, messages replaced with a compressed summary containing memory references.

---

## Governance and Privacy

**Private to the Synthetic:** emotional state, memories, private notes, SQLite workspace
**Organisational (visible to managers):** Governor events, message participation, task completion

GovernorEvents are filed to HubSystem when the Governor blocks an action. They form a compliance feed — patterns in Governor events trigger welfare checks, not direct inspection of private state.

Welfare checks are structured conversations conducted by an HR Archetype. The HR Synthetic has no special database access — it reads observable behaviour and probes gently, like a good human HR professional.

---

## Custom Pages / Tool Hosting

HubSystem acts as a WebSocket broker between browser-based custom pages and Synthetic Tools. No ports are exposed from the Synthetic container.

```
Browser JS  →  HubSystem WebSocket feed  →  Synthetic inbox  →  Tool event loop
Browser JS  ←  HubSystem WebSocket feed  ←  Synthetic reply  ←  Tool response
```

OAuth callbacks are handled by a generic Rails controller that routes the callback as an event to whichever Synthetic registered interest in that session token. The Synthetic owns all provider-specific logic.