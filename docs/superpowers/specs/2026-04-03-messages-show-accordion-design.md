# Messages Show — Accordion Conversation View

## Goal

Replace the standalone "document" Messages Show page with a conversation-in-context view. The selected message's row expands inline within the same MessagesGrid used by Conversations Show. Each message retains its own URL (`/messages/:id`). Turbo prefetch and morphing make navigating between messages feel like scrolling through a single page.

## Changes

### 1. Redcarpet gem

Add `redcarpet` to the Gemfile for Markdown rendering. Message contents (especially from LLMs) need proper formatting — line breaks, code blocks, lists.

### 2. Grid component

`Components::Grid#row` gains:

- `id:` parameter (optional) — renders as the HTML `id` attribute on the row's outer div.
- Block parameter (optional) — when provided, a full-width content div renders below the row's cells. This is the "expanded" state.

The expanded row gets `data-scroll-anchor-target="selected"` so the `scroll-anchor` Stimulus controller can scroll to it.

`scroll_to` gains a `:selected` option alongside existing `:first`/`:last`. When `:selected`, the controller scrolls the `[data-scroll-anchor-target="selected"]` element to the top if it's the first row, or centres it otherwise.

### 3. MarkdownViewer component

New Phlex component: `Components::MarkdownViewer`.

- `prop :content, String` — the markdown text.
- `prop :attributes, Hash, :**` — HTML attributes merged via `mix`.
- Renders an `article` tag with parsed Markdown inside.
- Uses `Redcarpet::Render::Safe` with `:hard_wrap`, `:fenced_code_blocks`, `:no_intra_emphasis`.
- Output via `unsafe_raw` (Safe renderer strips dangerous HTML).

### 4. MessagesGrid component

New props:

- `selected_message` — `_Nilable(Conversation::Message)`, default `nil`. When set, that message's row renders expanded with a `MarkdownViewer` showing its full contents.
- `show_subject` — `_Boolean`, default `true`. When `false`, the subject column is omitted.

Other changes:

- Each row gets `id: dom_id(message, :grid_row)`.
- When `selected_message` is set, passes `scroll_to: :selected` to the Grid.

### 5. Messages Show view

`Views::Messages::Show` mirrors `Views::Conversations::Show`: same tab bars, participants sidebar, pagination, reply form, close button, turbo stream. The only differences:

- Passes `selected_message: @message` and `show_subject: false` to MessagesGrid.
- `return_href` points to `conversations_path`.

Source comments note the duplication: "twice is a marker, three times refactor".

### 6. Messages Show controller

`MessagesController#show` loads the conversation and its paginated messages alongside the selected message:

```ruby
def show
  @message = Current.user.messages.find(params[:id])
  @conversation = @message.conversation
  @messages = @conversation.messages.page(page_number)
end
```

### 7. Conversations Show view

Passes `show_subject: false` and `selected_message: nil` to MessagesGrid. No other changes.

### 8. Messages Index view

Passes `show_subject: true` and `selected_message: nil` to MessagesGrid. Unchanged behaviour.

## Testing

- **Grid component spec**: `row` with `id:` renders HTML id. `row` with block renders expanded content. `scroll_to: :selected` option.
- **MarkdownViewer spec**: Renders paragraphs, line breaks, fenced code blocks. Strips raw HTML. Merges attributes via `mix`.
- **MessagesGrid spec**: `show_subject: false` omits subject column. `selected_message` renders expanded row with MarkdownViewer. Each row gets `dom_id`.
- **MessagesController spec**: `show` assigns conversation, paginated messages, and selected message.

All specs use fixtures for speed.

## Future considerations

- Turbo Frames per row as progressive enhancement (Option C from brainstorming).
- Attachment rendering in expanded rows.
- API endpoints mirroring the same resource structure.
