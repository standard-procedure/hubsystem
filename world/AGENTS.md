# world/ — Synthetic Runtime

## What this is

The world Synthetics live in. Long-running Ruby processes supervised by `async-service`. Synthetics communicate with the outside world exclusively via the HubSystem JSON API and WebSocket — they are API users of `server/`, nothing more.

## Why minimal Rails (not plain Ruby)

RubyLLM requires `Rails.application` for model persistence (LLM context messages stored via ActiveRecord). ActiveRecord outside a Rails app causes implicit dependency failures: MessageVerifier, `Rails.env`, secrets, railtie initialisers. A bare `Rails::Application` that requires only `active_record` and `ruby_llm` satisfies all of these without booting a web server.

There are no routes, no controllers, no views, no Puma.

## Key directories

```
world/
  config/
    application.rb         Minimal Rails::Application — no web stack
    database.yml           SQLite per-Synthetic workspace DBs
    credentials.yml.enc    Must share secret_key_base with server/ for
                           encrypted attribute compatibility
  lib/
    synthetic/
      service.rb           Async::Service::Generic subclass — one per running Synthetic
      event_loop.rb        The main loop: receive → pipeline → yield
      pipeline/
        threat_assessment.rb
        emotional_processing.rb
        llm_call.rb
        governor.rb
        memory_processing.rb
        capacity_processing.rb
      tool.rb              Base class for deterministic Tools
      tools/               Individual Tool implementations (Ruby scripts)
      archetype.rb         Loads Archetype config (OS prompt, Governor prompt,
                           skill access, LLM tier assignments)
  service.rb               async-service entry point — declares all running Synthetics
```

## Entry point

`service.rb` in the root of `world/` is the `async-service` configuration. It declares each running Synthetic as a supervised service:

```ruby
#!/usr/bin/env async-service

service "sid-security-consultant" do
  service_class Synthetic::Service
  synthetic_id 17
  archetype "SecurityConsultant"
end
```

`container.run(count: 1, restart: true)` provides automatic restart on crash. Adding a Synthetic to the organisation = adding a service declaration here.

## Resource model: nested semaphores

Synthetics run inside an `Async::Semaphore` capping their share of container cycles. Tools are nested inside a further semaphore carved from the Synthetic's own budget. This means:

- Spawning many Tools degrades the Synthetic's own responsiveness — emergent disincentive
- Long-running bash calls block a fiber and slow inbox processing — Synthetics are naturally incentivised to write proper async Tools instead

## The processing pipeline

Every incoming message passes through these stages in order:

1. **Threat Assessment** — classification (prompt injection, hostility, prior notes about sender retrieved via RAG)
2. **Emotional Processing** — update internal emotional state
3. **LLM Call** — system prompt updated with current personality + emotional state; agentic loop with tool calls
4. **Governor Module** — check response against Archetype's professional constraints; file `GovernorEvent` to HubSystem API if blocked
5. **Memory Processing** — update personal memories and relationship notes in SQLite
6. **Secondary Emotional Processing** — update emotional state post-response
7. **Capacity Processing** — check context window pressure; trigger sleep/compaction if needed

## Tools vs Synthetics

Tools are deterministic Ruby scripts spawned via an LLM tool-call:

```ruby
run_tool(script: "~/sid/harrys_xero_page.rb", concurrency: 2, input: "...")
```

| | Synthetic | Tool |
|---|---|---|
| Backed by | LLM | Ruby code |
| Behaviour | Emergent | Deterministic |
| Lifespan | Persistent | Ephemeral (TTL) |
| Pipeline | Full cognitive pipeline | Fixed protocol (case statement on message type) |

Tools inherit from `Synthetic::Tool`. They run their own event loop, yield cooperatively, and report to their owner Synthetic on completion or error.

## LLM tiers

Archetypes specify which model to use for which processing stage. Available tiers:

```
classifier:     fast classification (threat assessment, routing)
conversational: always-on general interaction
analytical:     research, planning, document synthesis
technical:      code, architecture, debugging
frontier:       novel/high-stakes problems
private:        sensitive data — local model, never leaves machine
embedding:      RAG retrieval and memory search
vision:         screenshots, OCR, UI understanding
```

LLM configuration is in `config/llm_tiers.yml`. Each Archetype config maps pipeline stages to tiers.

## Memory and emotional state

- Emotional state: numeric values stored in the Synthetic's SQLite workspace
- Memories: stored in SQLite with `emotional_impact` (0–100) and `emotional_valence` (:positive/:negative/:mixed)
- Private notes: relationship notes about other users, retrieved during Threat Assessment
- All of this is **private** — never sent to HubSystem except as a GovernorEvent

## Sleep / compaction

When `Capacity Processing` determines the context window is too large:
1. Messages beyond a recency threshold are summarised
2. Key facts extracted and written to SQLite memories
3. Messages replaced with compressed summary + memory references
4. On next wake: lightweight memory orientation before resuming inbox

## Communicating with server/

All communication via HubSystem API. Use the `HubSystem::Client` wrapper in `lib/synthetic/hub_system/client.rb`:

```ruby
hub.post_message(conversation_id:, content:)
hub.fetch_tasks(assigned_to: synthetic_id)
hub.file_governor_event(rule_violated:, action_blocked:, severity:)
hub.publish_to_page(feed_id:, payload:)
```

Never access `server/`'s database directly. Never share models between `server/` and `world/`.

## Testing

- RSpec for unit tests on pipeline modules and Tools
- Outside-in: test Observable behaviour via the HubSystem API, not internal state
- Use VCR or WebMock for LLM call fixtures in unit tests
- Integration tests spin up a test HubSystem instance

## What does NOT belong here

- Web routes, controllers, views
- Puma or any web server
- Shared database access with `server/`
- Any UI rendering (custom pages are served by `server/`, events routed here)