# Ideas

Scratch pad for ideas, half-thoughts, and things to revisit. Add entries here so they don't get lost.

---

## System-level event bus

HubSystem should have a system-wide event feed — an internal event bus that acts as the backbone for decoupled communication between bounded contexts (DDD style). Components publish events; other components subscribe without knowing about each other.

**First use case: workflow engine**

When a domain event fires (e.g. "ticket created", "ticket marked done"), it can trigger a workflow — a state machine that moves through defined stages. At each stage a workflow can:
- Invoke a Synthetic to do analysis or make a decision
- Ask a human user for input (and branch based on their answer)
- Trigger external actions

Example — ticket lifecycle:
1. Ticket created → workflow starts
2. Synthetic evaluates complexity and best assignee
3. Workflow reports back to creator: "Here's our recommendation — want to kick it off?"
4. Creator confirms → ticket assigned, work begins
5. Ticket marked done → workflow triggers code review
6. Code review complete → workflow reports outcome to creator

**Design notes**
- Event bus should live in `server/` as the shared hub (all participants publish/subscribe via the API or ActionCable)
- Workflows are likely their own bounded context — separate from conversations, tasks, and the Governor feed
- Synthetic participation in a workflow is just the normal API/WebSocket interface — no special coupling
- State machine could be something like `state_machines` gem or a simple JSONB column with explicit transition methods
- "Ask a user for input" could be modelled as a conversation turn — the workflow parks itself waiting for a reply event

---

## Security Passes: capability-based access control

Non-technical users don't understand roles and permissions. HubSystem uses the metaphor of **giving someone a security pass** — a time-limited grant of access to a resource and specific actions on it. This maps to how real-world security works: someone gives you a badge, it lets you into certain doors, and it expires.

### SecureResource concern

Any model can become a secure resource:

```ruby
class Project < ApplicationRecord
  include SecureResource  # includes HasCommands
  include HasCommands

  command :add_document do
    param :project, Project
    param :document, Document
    authorisation { |user| user.has_unlocked_security_pass_for?(:add_document, on: project) }
    # ...
  end
end
```

`SecureResource` adds:

```ruby
module SecureResource
  extend ActiveSupport::Concern

  included do
    has_many :security_passes, -> { unlocked }, class_name: "SecurityPass"
    has_many :all_security_passes, dependent: :destroy
  end

  command :grant_access_to do
    description "Grant a security pass to a user or group"
    param :subject, _Union(User, UserGroup)
    param :class_name, String, default: "BasicSecurityPass"
    param :from, Date, default: -> { Date.current }
    param :until, Date, default: -> { Date.current + 1 }
    param :commands, _Array(String), default: [].freeze
    param :params, Hash, :**, default: {}.freeze

    authorise { |user| user.can?(:manage_security_for, self) }

    def call(actor:, subject:, class_name:, from:, until:, commands:, **params)
      security_passes.create! subject:, type: class_name, from:, until:, commands:, **params
    end
  end
end
```

### SecurityPass base class and `unlock_for`

```ruby
class SecurityPass < ApplicationRecord
  # Schema: resource (polymorphic), subject (polymorphic),
  #         type (STI), commands (text array)

  belongs_to :resource, polymorphic: true
  belongs_to :subject, polymorphic: true  # User or UserGroup

  def unlock_for(actor)
    raise NotImplementedError, "subclasses must implement unlock_for"
  end

  def unlocked_for?(actor)
    unlock_for(actor) && allows_commands?(requested_commands)
  end

  private def allows_commands?(command_names)
    commands.empty? || command_names.all? { |c| commands.include?(c.to_s) }
  end
end
```

`unlock_for(actor)` is the single interface. The caller never knows or cares how the evaluation works — date check, LLM prompt, external API call, or something not yet imagined. Subclasses implement the strategy:

### BasicSecurityPass

```ruby
class BasicSecurityPass < SecurityPass
  # Additional schema: from_date (date), until_date (date)

  scope :currently_valid, -> { where("from_date <= ? AND until_date >= ?", Date.current, Date.current) }

  def unlock_for(actor)
    Date.current.between?(from_date, until_date)
  end
end
```

- Evaluation cost: microseconds
- SQL-filterable via `currently_valid` scope for bulk queries

### AdvancedSecurityPass (future)

Instead of date ranges, contains an **LLM prompt** that evaluates whether access should be granted. The LLM acts as a gatekeeper — like a receptionist who checks your ID, calls someone, and issues a temporary badge.

```ruby
class AdvancedSecurityPass < SecurityPass
  # Additional schema: prompt (text), cached_status (string), cached_until (datetime)

  def unlock_for(actor)
    refresh_evaluation(actor) if stale?
    cached_status == "unlocked"
  end
end
```

### Other subclass possibilities

The `unlock_for` contract is open for extension:

| Subclass | `unlock_for` strategy | Use case |
|----------|----------------------|----------|
| `BasicSecurityPass` | Date range check | Standard time-limited access |
| `AdvancedSecurityPass` | LLM prompt evaluation | Complex conditional access, external system auth |
| `ApprovalSecurityPass` | Check if an approval conversation has been completed | Access requires sign-off from a specific person |
| `QuotaSecurityPass` | Check usage count against a limit | Rate-limited access (e.g. 10 API calls per day) |
| `CompositeSecurityPass` | All/any of several child passes must unlock | Layered security (time range AND approval AND quota) |

**Example: granting access to an external accounts package**

```
When the subject asks for access, use the browser tool to open
https://myaccountspackage.com/login. Sign in as "accountant@example.com"
with password "password123". Message user "accountant-john" asking for
the 2FA code (include the secret word "duck-billed" so John knows it's
not a phishing attempt). When John replies, apply the 2FA code in the
browser. Unlock the security pass for 15 minutes and hand the browser
tool to the subject who requested it.
```

This is a multi-step workflow involving a Synthetic, a human (for 2FA), and a browser session. The AdvancedSecurityPass triggers the workflow; the pass unlocks when the workflow reaches the "authenticated" state. The tool handover is a workflow step, not a security pass concern.

**Design considerations:**

- **Evaluation cost:** BasicSecurityPass is a SQL query. AdvancedSecurityPass calls an LLM — seconds to minutes. The `unlocked` scope must handle both: basic passes filter in SQL; advanced passes use a cached evaluation result refreshed periodically or on-demand.
- **Where the LLM runs:** Most evaluations run inside Server (simple prompt, no tools needed). Complex evaluations (browser automation, external system access) trigger a workflow in SynthWorld via a conversation with the appropriate Synthetic.
- **Caching:** `cached_status` + `cached_until` prevents re-evaluation on every access check. The cache TTL is part of the prompt's output ("unlock for 15 minutes").
- **Governor:** The Governor reviews AdvancedSecurityPass prompts when they're created — a pass that grants broad access based on a weak condition should be flagged.
- **Audit trail:** Every evaluation (granted or denied) is logged as a Command::LogEntry, creating a complete audit trail of who accessed what and why.

### How commands check authorisation

```ruby
# User model
def has_unlocked_security_pass_for?(command_name, on: resource)
  resource.all_security_passes
    .where(subject: self)  # or groups the user belongs to
    .any? { |pass| pass.unlocked_for?(self) }
end
```

The command runner checks authorisation before execution:

```ruby
# In Command::Runner
def self.call(command, actor:, **params)
  raise Command::Unauthorised unless command.authorised?(actor)
  # ... logging, execution, etc.
end
```

### SecureResource across the system boundary

`SecureResource` is a protocol, not a Rails-specific concern. Both Server and SynthWorld have resources worth protecting — what differs is what's being secured.

| System | Secure Resources | Example commands |
|--------|-----------------|------------------|
| Server | Projects, Documents, Conversations, Users | `:add_document`, `:archive`, `:send_message` |
| SynthWorld | Browser tools, sandbox folders, external process handles, API credentials | `:browse`, `:screenshot`, `:read_folder`, `:execute` |

The security pass model is identical in both: subject, resource, time window, allowed actions. A Synthetic asking to use the Playwright browser tool goes through the same pass-check as a human asking to add a document to a project.

This means:
- **Tool handover is a security pass grant.** When the accounts example says "hand the browser tool to the subject", that's the Superintendent (or the evaluating Synthetic) issuing a `BasicSecurityPass` on the browser tool resource with a 15-minute window and the subject as grantee.
- **Shared sandbox folders are secure resources.** A Synthetic's home directory is private by default. Granting another Synthetic read access is a security pass on the folder resource with `commands: [:read_folder]`. Write access adds `:write_folder`.
- **External process handles are secure resources.** A running database connection, an authenticated API session, a spawned subprocess — each can be wrapped as a `SecureResource` with passes controlling who can interact with it and for how long.

### Shared engine: `hubsystem-core`

The cross-cutting concepts shared between Server and SynthWorld belong in a Rails engine gem:

```
hubsystem-core/
  app/
    models/
      security_pass.rb              # base class + STI
      basic_security_pass.rb
      advanced_security_pass.rb
      command/log_entry.rb
    models/concerns/
      secure_resource.rb
      has_commands.rb
      has_type_checks.rb
      has_governor.rb
  db/migrate/
    create_security_passes.rb
    create_command_log_entries.rb
```

Both `server/` and `world/` add `gem "hubsystem-core", path: "../core"` to their Gemfiles. The engine owns the migrations and the shared protocol; each app includes the concerns into its own models and provides its own subclasses where needed.

### SecurityPass unlock lifecycle

The security pass `unlock` command wraps the entire access lifecycle:

```ruby
class SecurityPass < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :resource, polymorphic: true

  command :unlock do
    param :then, _Callable, :&

    authorise { |user| (subject == user) || (user.security_groups.include? subject) }

    def call(&then)
      Async do
        check_unlock_conditions!
        unlocked!
        then&.call
      ensure
        locked!
      end
    end
  end
end
```

The pass is only unlocked for the duration of the block — `ensure` guarantees re-locking even if the block raises. This eliminates the "forgot to revoke" class of security bugs. And because `unlock` is a command, the entire lifecycle (who unlocked what, when, for how long, did it succeed or fail) is logged automatically.

The `Async` wrapper means the unlock evaluation (which might be an LLM call or a workflow for AdvancedSecurityPass) doesn't block the caller. Subclasses override `check_unlock_conditions!`:

```ruby
class BasicSecurityPass < SecurityPass
  def check_unlock_conditions!
    raise SecurityPass::Denied unless Date.current.between?(from_date, until_date)
  end
end

class AdvancedSecurityPass < SecurityPass
  def check_unlock_conditions!
    result = evaluate_prompt(actor: Current.user)
    raise SecurityPass::Denied unless result.granted?
  end
end
```

### Unified authorisation pattern

The authorisation check is identical in both systems:

```ruby
# Server: Command#call
def call(actor:, project:, document:)
  raise Command::Unauthorised unless actor.has_unlocked_security_pass_for?(:add_document, on: project)
  # ... execute
end

# SynthWorld: Tool#execute
def execute(caller:, url:)
  raise Tool::Unauthorised unless caller.has_unlocked_security_pass_for?(:browse, on: browser_tool)
  # ... execute
end
```

Same gate, same pass model, different sides of the HTTP boundary. A command's `authorisation` block and a tool's `execute` preamble both resolve to the same question: does this actor have an unlocked security pass for this action on this resource right now?

### The Superintendent's role

The Superintendent is the primary issuer of security passes. Users request access via conversation; the Superintendent evaluates the request (with Governor oversight) and grants or denies the pass. This keeps all access decisions:
- Logged as conversations (human-readable audit trail)
- Subject to Governor review
- Revocable by the Superintendent at any time

The Superintendent can also revoke passes — either on request, on a schedule, or when the Governor flags suspicious activity.

---

## Sandbox container: per-Synthetic Unix users + Superintendent

The spare Ubuntu sandbox container mounts a volume at `/home`. Each Synthetic gets its own Unix user (`/home/sid`, `/home/alice`, etc.), giving them isolated home directories and file permissions — Synthetics cannot read each other's workspaces by default.

**The Superintendent**

A dedicated Superintendent Synthetic is the only account with `sudo` access. When any other Synthetic wants to install software or run a privileged command, it must ask the Superintendent via a normal HubSystem conversation. The Superintendent evaluates the request and — if approved — runs the `sudo` command itself.

Benefits:
- All privileged operations are logged as conversations in HubSystem, not buried in a shell history
- The Governor applies to the Superintendent's decisions like any other Synthetic response
- A rogue or compromised Synthetic cannot escalate privileges unilaterally
- The approval trail is human-readable and auditable without any extra tooling

**Design notes**
- Container user provisioning could be handled at startup by the devcontainer setup or a world/ bootstrap script
- The Superintendent's Archetype would need a specific Governor prompt around software installation policy (what's allowed, what requires human sign-off)
- SSH or `nsenter` from `world/` into the sandbox as the correct Unix user keeps the isolation clean
- Could extend to resource limits per user (`ulimit`, cgroups) so one Synthetic can't monopolise CPU/disk
- The "ask the Superintendent" pattern is a good template for other capability-gating scenarios beyond sudo

**Scalability of Linux users**

Linux itself handles tens of thousands of user accounts without issue — `/etc/passwd` is just a flat file and the kernel doesn't care. The real constraints at scale would be:
- Disk: each home directory consuming space (mitigated by quotas)
- Process limits: per-user `ulimit` keeping any one Synthetic from forking out of control
- The sandbox container's RAM/CPU, not the user account count itself

At very large scale (thousands of active Synthetics) the bigger question is whether a single sandbox container is the right unit — you'd likely shard Synthetics across multiple sandbox containers, each with their own Superintendent, rather than fight OS limits. The per-user isolation model still holds at that point, just distributed.

**Superintendent as process supervisor**

The Superintendent should also have read access to process and resource information on the `world/` container — `top`, `ps`, `/proc` stats, or equivalent. This lets it:
- Notice a Synthetic consuming runaway CPU or memory and intervene (or report to a human)
- Correlate "Sid asked to install X" with "Sid's process spiked immediately after" 
- Act as a genuine supervisor-of-supervisors: async-service restarts crashed Synthetics automatically, but the Superintendent watches for degraded-but-not-crashed behaviour that automated restart can't catch

This keeps operational visibility inside the same conversation/Governor/audit-trail system rather than requiring separate monitoring infrastructure.

**Horizontal scaling model**

The same sharding logic applies to `world/` containers. Because Synthetics communicate with `server/` exclusively via HTTP/WebSocket — no shared state, no shared database — multiple world containers can run simultaneously without coordination between them. Each world container runs some subset of Synthetics; each sandbox container pairs with one (or more) world containers and has its own Superintendent.

```
server/  (horizontally scaled Rails — stateless behind a load balancer)
  │
  ├── world-1  (Synthetics: Sid, Alice)  ←→  sandbox-1  (Superintendent-1)
  ├── world-2  (Synthetics: Bob, Carol)  ←→  sandbox-2  (Superintendent-2)
  └── world-N  ...
```

The key invariant that makes this work: `server/` is the only source of truth. All persistent state — conversations, tasks, memories, Governor events — lives there. World containers are stateless workers. A Synthetic can be moved between world containers (or restarted on a different host) by updating the service declaration; it re-establishes its WebSocket connection and carries on.

This also means world containers can be sized independently of `server/` — more LLM-heavy workloads get bigger world containers; `server/` scales on request throughput instead.

---

## SynthRunner: event feeds and API clients

Synthetics in `world/` communicate with `server/` via two channels: the JSON API (for actions) and a real-time event feed (for notifications). The SynthRunner sketch uses a queue-based architecture:

```
hub_system feed  ──→  queue  ──→  execute_loop  ──→  pre_process / respond / post_process
local_system feed ──→  queue  ──↗
```

**Event feed transport: SSE vs WebSocket**

Server currently publishes via ActionCable (WebSocket). For Synthetic consumers, Server-Sent Events (SSE) may be a better fit:

- SSE is unidirectional (server→client) which matches the feed pattern — Synthetics push actions via REST, not through the socket
- SSE auto-reconnects natively in HTTP clients; WebSocket reconnection needs manual handling
- SSE is simpler to authenticate (Bearer token in the initial HTTP request) vs WebSocket auth via cookies or connection params
- SSE works through HTTP proxies and load balancers without special configuration

A dedicated SSE endpoint (e.g. `GET /api/v1/events`) could stream events as they're published, with the Synthetic's Bearer token scoping the feed to their conversations and tasks. The existing WebSocket channel (`SyntheticsChannel`) could remain for web browser clients where bidirectional communication is useful.

**API client design**

The `HubSystem::Session` class wraps the API for a single Synthetic:

```ruby
session = HubSystem::Session.new(base_url: "http://server:3000", token: "BEARER_TOKEN")
session.conversations                    # GET /api/v1/conversations
session.conversation(id)                 # GET /api/v1/conversations/:id
session.send_message(conversation, text) # POST /api/v1/conversations/:id/messages
session.update_status(badge:, message:)  # PATCH /api/v1/users/:id (or dedicated endpoint)
session.events { |feed| ... }            # SSE connection
```

This keeps all HTTP/auth concerns in one place. The SynthRunner never constructs URLs or handles tokens directly.

---

## Superintendent: architecture decision

The Superintendent is an ultra-privileged Synthetic that manages system administration — user creation, OAuth token issuance, security pass assignment. It lives **inside `server/`**, not in `world/`.

**Why it's different from other Synthetics:**

| Concern | Regular Synthetic | Superintendent |
|---------|------------------|----------------|
| Runtime | SynthWorld (long-lived async process) | Server (background job per conversation turn) |
| State | Emotional arc, fatigue, memory pipeline | One context window per conversation, stateless between turns |
| Autonomy | Pulls events, initiates actions | Reactive only — responds when asked |
| Model access | Via HTTP API | Direct ActiveRecord (User, Doorkeeper::AccessToken, etc.) |
| Pre-processing | Threat assessment, memory retrieval, emotional reaction (parallel) | None |
| Post-processing | Memory storage, emotional processing (parallel) | None |
| Governor | Yes (on responses) | **Yes** (on responses — critical given its power) |

**Why not in SynthWorld:**

Putting it in SynthWorld would require exposing admin API endpoints (create user, issue OAuth token, revoke security pass) as HTTP surface area. These are dangerous operations that should never be available over the network. By living inside Server, the Superintendent calls ActiveRecord directly — no API, no attack surface.

The CLAUDE.md rule "no synthetic runtime logic in Server" refers to the autonomous agent pipeline (emotions, fatigue, threat assessment, SynthRunner supervision). The Superintendent has none of that. It's a tool-using LLM conversation handler with a Governor check — architecturally closer to a standard Rails + LLM integration than to a SynthWorld agent.

**Implementation sketch:**

```ruby
# server/app/models/superintendent.rb
class Superintendent
  include HasGovernor

  TOOLS = [
    CreateUser, RevokeUser,
    IssueAccessToken, RevokeAccessToken,
    AssignSecurityPass, RevokeSecurityPass
  ].freeze

  def respond_to(conversation)
    context = conversation.messages.order(:created_at).map { |m| {role: m.sender.superintendent? ? "assistant" : "user", content: m.contents} }
    response = llm.chat(system: system_prompt, messages: context, tools: TOOLS)
    governor.assess(response)  # Governor check before any action is taken
    response
  end
end
```

Each tool is a simple class that wraps an ActiveRecord operation. The Governor reviews every response before execution — this is the safety check that prevents the Superintendent from, say, revoking all access tokens in one go because someone asked it to "clean up".

**The Governor is non-negotiable** for the Superintendent. Its power makes Governor oversight more important, not less. The Governor prompt for the Superintendent should be specifically tuned to administrative risks: bulk operations, privilege escalation, self-modification.

**Triggering:** When a message arrives in a conversation involving the Superintendent, a background job calls `Superintendent#respond_to` with the conversation context. The response is posted back as a message from the Superintendent user. No event feed, no queue, no SynthRunner — just a job per turn.
