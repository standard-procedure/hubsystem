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

A synthetic's fatigue (0-100) represents how full its LLM context is, calculated from actual token counts against the model's context window. The [capacity evaluator](app/modules/synthetic/capacity_evaluator.rb) updates this after each message. At 80%+, the [compactor](app/modules/synthetic/compactor.rb) triggers — the synthetic "sleeps", summarising older messages and extracting key facts into permanent [memories](app/models/synthetic/memory.rb).

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

## Memory & Documents

### Synthetic::Memory

[Memories](app/models/synthetic/memory.rb) are private to each synthetic. They store facts, preferences, and observations extracted by the [memory processor](app/modules/synthetic/memory_processor.rb) during conversation. Each memory has `content` (text) and `tags` (JSON array) for topic-based retrieval.

Search is tag-based (`.tagged_with`) and text-based (`.search`). Vector embeddings for semantic search will be added when the project migrates to PostgreSQL with pgvector.

### Document

[Documents](app/models/document.rb) are public knowledge — visible to all users. Any user (human or synthetic) can create documents. Like memories, they have `title`, `content`, and `tags` for search.

## Conversations

[Conversations](app/models/conversation.rb) are exchanges between two users (human or synthetic). Each conversation has an initiator and a recipient.

### Lifecycle

1. **Requested** — initiator creates a conversation request
2. **Active** — recipient accepts; both parties can exchange [messages](app/models/message.rb)
3. **Closed** — either participant closes, or recipient rejects a request

State transitions use [RESTful nested resources](DEVELOPMENT-PATTERNS.md#restful-state-transitions): `ConversationAcceptancesController`, `ConversationRejectionsController`, `ConversationClosuresController`.

### Unread tracking

Messages have a `read_at` timestamp. When a user views a conversation, all messages from the other participant are marked as read.

## Tasks

[Tasks](app/models/task.rb) are shared work items that any user (human or synthetic) can create, assign, and complete.

### Hierarchy

Tasks form a tree via `parent_id`. When all children of a task are completed (or cancelled), the parent auto-completes upward recursively. Cancelling a task cascades downward to cancel all its children.

### Dependencies

[TaskDependency](app/models/task_dependency.rb) records cross-task dependencies. A task with incomplete dependencies is blocked and cannot be completed.

### Notifications

On completion or cancellation, the task creator receives a message via an active conversation with the assignee.

### Reminders

Tasks with a `due_at` timestamp are picked up by [TaskReminderJob](app/jobs/task_reminder_job.rb), which runs every minute via SolidQueue's recurring job config, sending reminder messages to assignees.

### Scheduled / Repeating Tasks

Tasks with a `schedule` field (cron expression, parsed by [Fugit](https://github.com/floraison/fugit)) repeat automatically. When a scheduled task completes, a new pending task is created with the same subject, description, assignee, tags, and schedule, with `due_at` set to the next cron occurrence. Cancelling a scheduled task stops the recurrence.

### Web UI

Tasks are managed via [TasksController](app/controllers/tasks_controller.rb) accessible from the System knob in the CRT Monitor footer. The index shows two tabs: "Assigned to me" (active tasks) and "Created by me". Task show pages allow assignment (radio buttons), completion, cancellation, and adding subtasks.

State transitions use [RESTful nested resources](DEVELOPMENT-PATTERNS.md#restful-state-transitions): `TaskAssignmentsController`, `TaskCompletionsController`, `TaskCancellationsController`.

### Dashboard

The dashboard shows a task summary [status bar](app/components/status_bar.rb) with pending, blocked, and overdue counts, plus a [status matrix](app/components/status_matrix.rb) of the current user's conversations:
- **Nominal** (green) — active, all messages read
- **Warning** (amber) — unread messages
- **Critical** (red) — pending conversation request
- **Offline** (grey) — recently closed (within 24 hours, then removed)

## API

JSON API under `/api/v1/` authenticated via [Doorkeeper](config/initializers/doorkeeper.rb) OAuth 2.0 Bearer tokens.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/conversations` | List active conversations |
| GET | `/api/v1/conversations/:id` | Show conversation with messages |
| POST | `/api/v1/conversations` | Create conversation request |
| POST | `/api/v1/conversations/:id/acceptance` | Accept request |
| POST | `/api/v1/conversations/:id/rejection` | Reject request |
| POST | `/api/v1/conversations/:id/closure` | Close conversation |
| GET | `/api/v1/conversations/:id/messages` | List messages |
| POST | `/api/v1/conversations/:id/messages` | Send message |
| GET | `/api/v1/tasks` | List assigned tasks |
| GET | `/api/v1/tasks/:id` | Show task with children |
| POST | `/api/v1/tasks` | Create task |
| PATCH | `/api/v1/tasks/:id/assignment` | Assign task |
| POST | `/api/v1/tasks/:id/completion` | Complete task |
| POST | `/api/v1/tasks/:id/cancellation` | Cancel task |

### Authentication

Include a Bearer token in the Authorization header:
```
Authorization: Bearer <token>
```

OpenAPI documentation is auto-generated from request specs via [rspec-openapi](https://github.com/exoego/rspec-openapi):
```bash
OPENAPI=1 bundle exec rspec spec/requests/api/
```
