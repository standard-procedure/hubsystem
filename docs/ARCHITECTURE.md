# HubSystem Architecture

**Multi-tenant AI agent platform built in Rails**

See also: `~/cher/docs/hub-system-design.md` for complete design document

---

## Overview

HubSystem is a Rails 8 application for running persistent AI agents with:
- Memory (pgvector embeddings)
- Security (fine-grained access control)
- Multi-channel communication (web, API, mobile, TUI)

**Design philosophy:** Rails-idiomatic patterns, no clever abstractions, outside-in TDD.

---

## Core Models

### Organizational Structure

```
Organisation
  └── Locations (has_ancestry)
       └── Items (delegated_type)
```

**Location** — Recursive tree for organizing Items
- Company → Department → Team → Office
- `has_ancestry` gem for nested hierarchy

**Item** — Polymorphic via delegated_type (NOT STI!)
- Equipment: "MacBook Pro", "Conference Phone"
- Document: "Employee Handbook", "Q4 Strategy"  
- JobRole: "Senior Engineer" (linked to User)
- Agent: "Code Review Bot" (also a User!)

### Users

```
User (STI)
  ├── Person (humans)
  └── Agent (AI agents)
```

**Why STI here?** Users share authentication, authorization, and notification concerns.

**Agent as User:**
- Can send/receive messages
- Can have SecurityPasses
- Can be placed in Locations (via Item + delegated_type)
- Has memories (personal, class, knowledge base)

### Documents & Messages

```
Document (base class)
  └── Message (subclass)
```

**Document:**
- ActionText content (HTML + plain text)
- Auto-generated summaries (one line, one paragraph)
- Revisions tracking
- Attachments via ActiveStorage

**Message:**
- Belongs to Conversation
- Mentions users (@alice)
- Processed through pipeline

### Conversations

```
Conversation
  ├── Messages
  ├── ConversationMemberships → Users
  └── OutputChannels (delegated_type)
```

**Key insight:** Every message send is part of a conversation. Subscribing to a monitor = joining its group conversation.

### Output Channels

```ruby
OutputChannel (delegated_type)
  ├── TurboStreamChannel (web UI)
  ├── PushNotificationChannel (mobile)
  └── TUIChannel (terminal)
```

Same message, different formats. Channels decide how to render content/parts.

---

## Message Pipeline

```
ThreatAssessor → AuthorisationVerifier → MemoryRetriever
  ↓
AgentProcessor (LLM)
  ↓
MemoryRecorder → ResponseProcessor → OutputChannels
```

**No neuroscience metaphors!** Just a clear processing pipeline.

**Stages:**
1. **ThreatAssessor** — Rate limits, malicious content detection
2. **AuthorisationVerifier** — Check SecurityPass grants
3. **MemoryRetriever** — Fetch relevant memories (pgvector)
4. **AgentProcessor** — LLM processing with context
5. **MemoryRecorder** — Write new memories
6. **ResponseProcessor** — Deliver via OutputChannels

---

## Memory System

```
Memory
  ├── Personal (one agent)
  ├── Class (all agents of same type)
  └── Knowledge Base (org-wide)
```

**Implementation:**
- pgvector embeddings (1536 dimensions)
- Cosine similarity search
- JSONB metadata for filtering

**Context loading:**
Agents get message IDs + paragraph summaries. Full messages retrieved on demand.

---

## Security Model

```
SecurityPass → SecurityPassResource → Resource (polymorphic)
```

**Resource** mixin applied to:
- Conversations
- Documents
- Locations
- Equipment
- etc.

**Access levels:** read, write, admin (Literal enum)

---

## Testing Strategy

### Outside-In TDD

1. Write feature spec (Gherkin)
2. Write step definitions (web + API)
3. Red → Green → Refactor

### Dual Web/API

All features tested via BOTH:
- `spec/features/steps/web/` — Playwright browser tests
- `spec/features/steps/api/` — Request specs

**Why?** Proves feature parity. If web works but API doesn't (or vice versa), specs fail.

---

## Technology Choices

| Concern | Solution | Why |
|---------|----------|-----|
| **Polymorphism** | delegated_type | Avoids STI bloat |
| **Rich text** | ActionText | HTML + plain text |
| **Hierarchy** | has_ancestry | Battle-tested tree structure |
| **Search** | pgvector | Semantic similarity |
| **Testing** | Fixtures | DHH's fast approach |
| **Frontend** | Hotwire + Phlex | Server-rendered, minimal JS |
| **Linting** | StandardRB | Zero-config |
| **Type safety** | Literal | Runtime validation |

---

## Development Workflow

See `hubsystem-server/AGENTS.md` for complete guide.

**TL;DR:**
1. Write Gherkin feature spec
2. Write web + API step definitions
3. Run specs (RED)
4. Implement (controller → model → component)
5. Run specs until GREEN
6. Lint with StandardRB
7. Update OpenAPI docs

---

## Next Steps

1. **Location CRUD** — First feature, establish patterns
2. **Authentication** — Devise or custom
3. **Message pipeline** — Implement processing stages
4. **Memory system** — pgvector embeddings
5. **Output channels** — TurboStream first

---

**For implementation details**, see:
- `hubsystem-server/AGENTS.md` — Development guide
- `~/cher/docs/hub-system-design.md` — Full design doc
