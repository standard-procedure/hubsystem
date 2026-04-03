# Messages Show Accordion — Implementation Plan

Spec: `docs/superpowers/specs/2026-04-03-messages-show-accordion-design.md`

## Step 1: Add Redcarpet gem

- Add `gem "redcarpet"` to `server/Gemfile`
- Run `bundle install` inside the devcontainer

## Step 2: MarkdownViewer component + spec

**Files:**
- `server/app/components/markdown_viewer.rb`
- `server/spec/components/markdown_viewer_spec.rb`

**Component:**
- `prop :content, String`
- `prop :attributes, Hash, :**`
- Renders `article(**mix(class: [...], **@attributes))` with `unsafe_raw` of Redcarpet output
- Redcarpet config: `Redcarpet::Render::Safe`, extensions: `hard_wrap: true`, `fenced_code_blocks: true`, `no_intra_emphasis: true`

**Spec (follow pattern from `crt_monitor_spec.rb`):**
- Renders paragraphs from plain text
- Converts line breaks (hard_wrap)
- Renders fenced code blocks
- Strips raw HTML input
- Merges extra attributes via `mix`

## Step 3: Grid component — expanded rows + row IDs

**Files:**
- `server/app/components/grid.rb`
- `server/spec/components/grid_spec.rb` (new)

**Changes to Grid:**
- `row(*values, id: nil, &block)` — `id` renders as HTML `id` on the row div
- When block given, render a full-width `div(class: "grid-row-expanded")` after the cells, yielding the block
- The expanded row div gets `data: {scroll_anchor_target: "selected"}`
- `scroll_to` prop: add `:selected` to the `OneOf`

**Changes to scroll_anchor_controller.js:**
- Add `selected` case: find `[data-scroll-anchor-target="selected"]`, if it's the first child of the body scroll to top, otherwise `scrollIntoView({block: "center"})`

**Spec:**
- `row` renders a `div.grid-row`
- `row` with `id:` sets the HTML id
- `row` with a block renders `.grid-row-expanded` content
- `row` without a block does not render expanded content
- Header renders column labels

## Step 4: MessagesGrid — selected_message + show_subject props

**Files:**
- `server/app/components/messages/messages_grid.rb`
- `server/spec/components/messages/messages_grid_spec.rb` (new)

**Changes:**
- Add `prop :selected_message, _Nilable(Conversation::Message), default: nil`
- Add `prop :show_subject, _Boolean, default: true`
- When `show_subject` is false, omit the subject column from the columns array
- Each row: `id: dom_id(message, :grid_row)`
- When message matches `selected_message`: pass a block to `grid.row` that renders `MarkdownViewer content: message.contents`
- Pass `scroll_to: @selected_message ? :selected : :last` to Grid

**Spec:**
- Renders all four columns by default (including subject)
- `show_subject: false` omits subject column
- Each row has `dom_id(message, :grid_row)` as id
- `selected_message` renders expanded content for that row only
- Other rows do not have expanded content

## Step 5: Messages Show view + controller

**Files:**
- `server/app/views/messages/show.rb` (rewrite)
- `server/app/controllers/messages_controller.rb` (update show action)

**Controller changes:**
- `show` loads `@conversation = @message.conversation` and `@messages = @conversation.messages.page(page_number)`
- Renders with all needed props

**View:** Mirror `Views::Conversations::Show` structure:
- Same layout: turbo_stream_from, Column/Switcher, TabBar, Search, MessagesGrid, Users::TabBar, Paginate, close button, reply form
- Pass `selected_message: @message`, `show_subject: false` to MessagesGrid
- `return_href: conversations_path`
- Add source comment noting duplication with Conversations Show: "NOTE: this view intentionally mirrors Views::Conversations::Show — twice is a marker, three times refactor"

## Step 6: Conversations Show + Messages Index — pass new props

**Files:**
- `server/app/views/conversations/show.rb`
- `server/app/views/messages/index.rb`

**Conversations Show:**
- Pass `show_subject: false` to MessagesGrid (already in conversation context)
- No `selected_message` needed (nil default)

**Messages Index:**
- Pass `show_subject: true` to MessagesGrid (explicit, matches default)
- No `selected_message` needed (nil default)

## Step 7: Controller spec for MessagesController#show

**Files:**
- `server/spec/requests/messages_spec.rb` (new or update existing)

**Spec:**
- `show` renders successfully
- Assigns the correct message, conversation, and paginated messages

## Review checkpoint

Run full spec suite. Verify all specs pass. Manual smoke test in browser: navigate from Conversations Show, click a message, confirm the accordion view renders with the message expanded and the grid scrolls correctly.
