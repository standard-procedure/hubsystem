# Development Patterns

## Using OmniAuth in features
The Developer strategy is available in test mode and [feature tests](spec/turnip_helper.rb) are configured to [mock the OmniAuth provider](https://github.com/omniauth/omniauth/wiki/Integration-Testing).

To fake a login, find the relevant [user identity record](spec/fixtures/user_identities.yml) and add a mock authentication:

```ruby
OmniAuth.config.add_mock :developer, uid: @identity.uid
```

Then visit the log in page and click the "Developer login" button.  This will log in using the mock authentication and then redirect.

```ruby
visit some_path # If not logged in will redirect to new_session_path
click_on "Developer login" # Does a fake authentication
expect(page).to have_text "I am logged in"
```

## Writing Web Steps

Web steps must simulate real browser interaction. Use `visit` only for the initial page load (e.g. login). After that, navigate entirely through clicks — links, buttons, and nav controls.

### Playwright and @javascript

Features tagged with `@javascript` run under Playwright (headless Chromium) via the `capybara-playwright-driver` gem. This gives real browser behaviour — JavaScript execution, Turbo Drive navigation, Action Cable WebSockets — but introduces timing considerations.

The Gemfile must use `capybara-playwright-driver` (not just `playwright-ruby-client` which is only the API client without Capybara integration).

### CSS text-transform and case sensitivity

The design system uses `text-transform: uppercase` on buttons, nav items, and labels. Under Rack::Test, Capybara sees the source HTML text. Under Playwright, it sees the **rendered** text — all uppercase. This means `click_on "New Conversation"` fails because Playwright sees "NEW CONVERSATION".

Use case-insensitive regexes or CSS selectors instead of text matching:

```ruby
# Bad — breaks under Playwright with text-transform: uppercase
click_on "New Conversation"
expect(page).to have_content("Choose recipient")

# Good — case-insensitive
page.find("a.btn-primary", text: /new conversation/i).click
expect(page).to have_css(".radio-group")

# Good — CSS selector (no text matching)
page.find("label[for='recipient_#{bob.id}']").click
page.find(".btn-danger", text: /reject/i).click
```

### Waiting for Turbo navigation

Turbo Drive can double-trigger navigations during tests, detaching DOM elements between `find` and `click`. **Always** wait for the path to settle after clicking a navigation link:

```ruby
find("a[title='Messages']").click
wait_until { page.current_path == "/conversations" }
```

`wait_until` (from `spec/support/wait.rb`) polls a condition block until it returns truthy, with a 20-second timeout.

### click_with_retry

For navigation clicks that are prone to Turbo morph issues, use `click_with_retry` which rescues `Playwright::Error` and retries:

```ruby
def click_with_retry(selector, **opts)
  wait_until do
    begin
      page.find(selector, **opts).click
      true
    rescue Playwright::Error
      false
    end
  end
end
```

Use this for clicking links and buttons where Turbo may replace the DOM between find and click. Do **not** use it for form submissions where a retry could cause duplicate actions — use the form interaction pattern below instead.

### Navigation

Use the CRT Monitor knobs (identified by `title` attribute) and in-page links, always followed by a path wait:

```ruby
find("a[title='Dashboard']").click              # CRT Monitor nav knob
wait_until { page.current_path == "/" }

find("a[title='Messages']").click               # CRT Monitor nav knob
wait_until { page.current_path == "/conversations" }

click_with_retry(".nav-item", text: /archived/i) # In-page nav item
wait_until { page.current_path == "/conversations" }
```

On the dashboard, conversations appear as status matrix cells without text. Click them by href using `click_with_retry`:

```ruby
click_with_retry("a.matrix-cell[href='#{conversation_path(conversation)}']")
wait_until { page.current_path == conversation_path(conversation) }
```

### Forms

Turbo can detach form elements mid-interaction. Wrap the entire fill-and-submit sequence in a `wait_until` block that retries on `Playwright::Error`:

```ruby
wait_until do
  begin
    expect(page).to have_field("message[content]")
    fill_in "message[content]", with: "How are you?"
    page.find(".btn-primary", text: /send/i).click
    true
  rescue Playwright::Error, Capybara::ElementNotFound
    false
  end
end
```

For radio buttons styled as buttons, click the label by `for` attribute (see [Radio buttons](#radio-buttons-styled-as-buttons)):

```ruby
page.find("label[for='recipient_#{bob.id}']").click
```

### Simulating other users

When another user acts (e.g. Bob accepts a request), update the model directly. Then use `wait_until` before navigating to see the result:

```ruby
# Bob acts in the background
conversation.update!(status: :active)

# Alice navigates to see the change
wait_until { conversation.reload.active? }
find("a[title='Messages']").click
wait_until { page.current_path == "/conversations" }
click_with_retry(".conversation-item", text: /#{conversation.subject}/i)
wait_until { page.current_path == conversation_path(conversation) }
```

### What NOT to do

- Do not use `visit` after the initial login — click through the UI instead
- Do not check model state as a substitute for asserting what the page shows
- Do not use `page.driver` or other Capybara internals
- Do not use `click_on` with exact text when CSS `text-transform` is in play — use `page.find` with a regex or CSS selector
- Do not click navigation links without a subsequent `wait_until { page.current_path == ... }` — Turbo double-triggers cause stale element references

## Radio Buttons Styled as Buttons

Radio buttons can be styled to look like secondary/primary buttons using the `.radio-group` CSS class. The pattern uses hidden `<input type="radio">` elements with adjacent `<label>` elements:

```ruby
# In a Phlex view
div class: "radio-group" do
  @users.each do |u|
    input type: "radio", name: "conversation[recipient_id]", value: u.id, id: "recipient_#{u.id}", required: true
    label(for: "recipient_#{u.id}") { u.name }
  end
end
```

Unselected labels look like secondary buttons (transparent with border). The selected label gets primary button styling (green phosphor glow). The CSS handles the visual state via `input[type="radio"]:checked + label`.

In Playwright tests, click the label by its `for` attribute rather than by text (avoids uppercase issues):

```ruby
page.find("label[for='recipient_#{bob.id}']").click
```

## Turbo Broadcasts and Action Cable

### Broadcasting model changes

Use `Turbo::Broadcastable` to push updates to connected browsers:

```ruby
class Conversation < ApplicationRecord
  include Turbo::Broadcastable
  after_update_commit :broadcast_refresh
end

class Message < ApplicationRecord
  include Turbo::Broadcastable
  after_create_commit -> { broadcast_refresh_to conversation }
end
```

### Subscribing in Phlex views

Use `Phlex::Rails::Helpers::TurboStreamFrom` to subscribe:

```ruby
class Views::Conversations::Show < Views::Base
  include Phlex::Rails::Helpers::TurboStreamFrom

  def view_template
    turbo_stream_from @conversation
    # ... rest of view
  end
end
```

The layout's `turbo-refresh-method: morph` meta tag means `broadcast_refresh` will morph the page in-place rather than replacing it entirely.

### Action Cable connection

The WebSocket connection authenticates via the session cookie in [app/channels/application_cable/connection.rb](../app/channels/application_cable/connection.rb). Use the fully qualified `User::Session` — bare `Session` is not resolved within the `ApplicationCable` module.

### Known limitation: async-cable and Puma

The project uses `async-cable` for WebSocket support, which requires Falcon's async event loop. Puma (used as the Capybara test server) cannot run the async-cable middleware — WebSocket connections fail with "No async task available!".

This means Turbo broadcasts do not reach the browser during Playwright tests. The web steps work around this by navigating to see updated state rather than relying on live push. To enable live broadcasts in tests, the test server would need to switch to Falcon, or async-cable would need to be swapped for standard Action Cable in the test environment.

## RESTful State Transitions

State changes on resources are modelled as nested singular resources, each with its own controller. This keeps controllers focused and avoids custom actions.

### Pattern

```ruby
# config/routes.rb
resources :things do
  resource :approval, only: [:new, :create], controller: "thing_approvals"
end

# GET  /things/:thing_id/approval/new  -> ThingApprovalsController#new  (confirmation page)
# POST /things/:thing_id/approval      -> ThingApprovalsController#create (perform transition)
```

### Conversation examples

| Action | Route | Controller |
|--------|-------|------------|
| Accept a request | `POST /conversations/:id/acceptance` | `ConversationAcceptancesController` |
| Reject a request | `POST /conversations/:id/rejection` | `ConversationRejectionsController` |
| Close a conversation | `GET /conversations/:id/closure/new` | `ConversationClosuresController#new` |
| | `POST /conversations/:id/closure` | `ConversationClosuresController#create` |

### Why

- Each controller has a single responsibility
- Standard REST verbs — no custom actions like `PUT /conversations/:id/accept`
- Easy to add confirmation pages via `GET new`
- Clear authorisation boundaries per transition
