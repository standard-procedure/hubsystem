# WebSocket API — design for Synthetic real-time notifications

## Problem

Synthetics interact with HubSystem via the JSON API (HTTP). This works well for reads and writes, but means a Synthetic must poll to discover new events (new messages, conversation state changes, etc.). Since Synthetics run on Async fibers, a persistent WebSocket connection is a natural fit — they receive push notifications and react immediately.

## Design decisions

### Turbo Streams are not reused

The existing `broadcasts_refreshes` / `broadcasts_refreshes_to` declarations on Conversation and Message broadcast **HTML fragments** via Turbo Streams. These drive the web UI's live updates. They are not suitable for Synthetics, which need structured JSON data.

The WebSocket API uses a **separate ActionCable channel** that broadcasts JSON notifications.

### Notifications are signals, not payloads

A WebSocket notification tells the Synthetic **what happened**, not the full data:

```json
{"event": "message.created", "conversation_id": 42, "message_id": 7}
{"event": "conversation.updated", "conversation_id": 42}
```

The Synthetic then fetches details from the JSON API if needed. This keeps the channel thin and the API as the single source of truth for data shape. It avoids duplicating serialisation logic and means the API response format can evolve in one place.

### Authentication via Bearer token

The web UI authenticates ActionCable connections via session cookies. Synthetics authenticate via Doorkeeper Bearer tokens, passed as a query parameter on the connection URL:

```
wss://hub.example.com/cable?token=BEARER_TOKEN
```

`ApplicationCable::Connection` tries session cookies first, then falls back to the token parameter. This keeps web UI connections unchanged while supporting Synthetics.

### Writes stay on HTTP

Synthetics use the JSON API for all write operations (sending messages, accepting conversations, etc.). HTTP gives clear request-response semantics, status codes, and error handling. The WebSocket is subscribe-only from the client's perspective.

This means the Synth's interaction pattern is:

1. Connect to `/cable?token=...`
2. Subscribe to a notification channel (e.g. for a conversation, or a personal feed)
3. Receive JSON events as they happen
4. Write via the JSON API as before
5. Get confirmation of own writes as WebSocket events too (round-trip verification)

## Channel design

### `NotificationsChannel`

A single channel per user that delivers all events relevant to that user. The Synthetic subscribes once on connect.

```ruby
# app/channels/notifications_channel.rb
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

Broadcasting from models (via ActiveSupport callbacks or a concern):

```ruby
NotificationsChannel.broadcast_to(user, {
  event: "message.created",
  conversation_id: message.conversation_id,
  message_id: message.id
})
```

This is simpler than per-conversation subscriptions — the Synthetic doesn't need to manage subscriptions as conversations are created or closed. It just listens on one stream for everything.

## Testing

### Feature parity via Turnip/Gherkin

Feature specs run against two interfaces: `web` (Capybara/Playwright) and `api` (HTTP + WebSocket). The same `.feature` files exercise both.

The API test interface combines:
- **`ApiClient`** — HTTP requests with Bearer token auth (existing)
- **`CableClient`** — captures ActionCable broadcasts during the test

In test mode, ActionCable uses the `test` adapter. Broadcasts are captured in memory rather than sent over a real WebSocket. The `CableClient` module reads them via `ActionCable::TestHelper#broadcasts`.

### Combined assertions

A step like "then I receive the message" asserts both:
1. A WebSocket notification was broadcast for the event
2. The message is retrievable from the JSON API

```ruby
step "I receive the message" do
  # Push: notification was broadcast
  expect(cable_broadcasts_for(current_user)).to include(
    hash_including("event" => "message.created")
  )

  # Pull: data is correct via API
  get api_v1_conversation_messages_path(@conversation),
      headers: auth_header(@token)
  messages = JSON.parse(response.body)
  expect(messages.first["content"]).to eq(@expected_content)
end
```

### CableClient module

Uses `ActionCable::TestHelper#broadcasts(stream)` to read captured broadcasts from the test adapter.

```ruby
# spec/support/cable_client.rb
module CableClient
  include ActionCable::TestHelper

  def cable_broadcasts_for(user)
    stream = NotificationsChannel.broadcasting_for(user)
    broadcasts(stream).map do |raw|
      raw.is_a?(String) ? JSON.parse(raw) : raw
    end
  end

  def cable_received_event?(user, event)
    cable_broadcasts_for(user).any? { |b| b["event"] == event }
  end

  def clear_cable_broadcasts_for(user)
    stream = NotificationsChannel.broadcasting_for(user)
    broadcasts(stream).clear
  end
end
```

## What this does NOT cover

- Custom per-conversation channels — not needed if `NotificationsChannel` delivers everything
- Binary/file streaming over WebSocket
- Presence tracking (who is currently connected)
- Rate limiting or backpressure on the WebSocket

These can be added later if needed.
