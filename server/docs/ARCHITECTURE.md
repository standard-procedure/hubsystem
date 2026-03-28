# Architecture

## Users

[Users](app/model/user.rb) access the system and use inheritance to represent [humans](app/models/user/human.rb) and [synthetics](app/models/user/synthetic.rb) (controlled by LLMs).

### Humans

They can log in using [OmniAuth](config/initializers/omniauth.rb).

### Synthetics

Every synthetic uses a specific [LLM model](config/llm_models.yml), a personality and an emotional state.

#### Emotional State

Synthetics maintain eight emotions as integer percentages (0-100): joy, sadness, fear, anger, surprise, disgust, anticipation, trust. These are stored in the user's `data` JSON column via `has_attribute` and updated by the [emotional processor](app/modules/synthetic/emotional_processor.rb) during message processing.

#### Fatigue

A synthetic's fatigue (0-100) represents how full its LLM context is. The [capacity evaluator](app/modules/synthetic/capacity_evaluator.rb) updates this after each message. At 80%+, compaction (context summarisation) is needed.

#### LLM Context

Each synthetic has one [LlmContext](app/models/llm_context.rb) record (via [RubyLLM](https://rubyllm.com/rails/) `acts_as_chat`) which carries the full message history across all interactions. This is the synthetic's internal context — separate from the [Conversation](app/models/conversation.rb) messages which represent the joint conversation visible to both participants.

#### Processing Pipeline

When a synthetic receives a message, it passes through a [pipeline](app/modules/synthetic/pipeline.rb) of processing modules:

1. **[Threat Assessor](app/modules/synthetic/threat_assessor.rb)** — classifies the message as safe, risky, or blocked. Blocked messages are rejected.
2. **[Emotional Processor](app/modules/synthetic/emotional_processor.rb)** (incoming) — adjusts emotions based on how the message affects the synthetic.
3. **LLM Response** — the main LLM processes the message using the synthetic's full context and personality.
4. **[Governor](app/modules/synthetic/governor.rb)** — checks whether the response is appropriate. Blocked responses are replaced with a refusal.
5. **[Memory Processor](app/modules/synthetic/memory_processor.rb)** — extracts facts worth remembering (stub — persistence deferred).
6. **[Emotional Processor](app/modules/synthetic/emotional_processor.rb)** (outgoing) — adjusts emotions based on the synthetic's own response.
7. **[Capacity Evaluator](app/modules/synthetic/capacity_evaluator.rb)** — updates fatigue and flags if compaction is needed.

Processing modules (steps 1-2, 4-6) use a low-cost LLM (configured as `low` in [llm_models.yml](config/llm_models.yml)). The main response (step 3) uses a high-cost model (`high`).

## Conversations

[Conversations](app/models/conversation.rb) are exchanges between two users (human or synthetic). Each conversation has an initiator and a recipient.

### Lifecycle

1. **Requested** — initiator creates a conversation request
2. **Active** — recipient accepts; both parties can exchange [messages](app/models/message.rb)
3. **Closed** — either participant closes, or recipient rejects a request

State transitions use [RESTful nested resources](DEVELOPMENT-PATTERNS.md#restful-state-transitions): `ConversationAcceptancesController`, `ConversationRejectionsController`, `ConversationClosuresController`.

### Unread tracking

Messages have a `read_at` timestamp. When a user views a conversation, all messages from the other participant are marked as read.

### Dashboard

The dashboard shows a [status matrix](app/components/status_matrix.rb) of the current user's conversations:
- **Nominal** (green) — active, all messages read
- **Warning** (amber) — unread messages
- **Critical** (red) — pending conversation request
- **Offline** (grey) — recently closed (within 24 hours, then removed)
