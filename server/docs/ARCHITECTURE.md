# Architecture

## Users

[Users](app/model/user.rb) access the system and use inheritance to represent [humans](app/models/user/human.rb) and [synthetics](app/models/user/synthetic.rb) (controlled by LLMs).

### Humans

They can log in using [OmniAuth](config/initializers/omniauth.rb).

### Synthetics

Every synthetic uses a specific [LLM model](config/llm_models.yml), a personality and an emotional state.

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
