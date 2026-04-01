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

Web steps run through Rack::Test by default (fast, in-process). Use `visit` to navigate and `click_on` for links and buttons.

### Navigation

```ruby
visit root_path
visit conversations_path
visit conversation_path(conversation)
click_on "New Task"
click_on "Developer login"
```

### Simulating other users

When another user acts (e.g. Bob accepts a request), update the model directly. Then `visit` the page to see the result:

```ruby
# Bob acts in the background
conversation.update!(status: :active)

# Alice reloads to see the change
visit conversation_path(conversation)
```

### Forms

Use `fill_in` for text fields and `choose` for radio buttons:

```ruby
fill_in "conversation[subject]", with: "Hi Bob"
choose "recipient_#{bob.id}"
click_on "Send Request"
```

### @javascript tag (Playwright)

Features tagged with `@javascript` run under Playwright (headless Chromium) for real browser behaviour. This is slower and introduces timing issues — use only when JavaScript execution is required (e.g. Turbo broadcasts).

Under Playwright, CSS `text-transform: uppercase` changes visible text. Use case-insensitive regexes or CSS selectors:

```ruby
page.find("a.btn-primary", text: /new conversation/i).click
page.find("label[for='recipient_#{bob.id}']").click
```

Use `wait_until { page.current_path == expected }` after every navigation to let Turbo settle.

## Writing API Steps

API feature steps make real HTTP requests with Bearer tokens via the `ApiClient` module ([spec/support/api_client.rb](../spec/support/api_client.rb)). They exercise the same Gherkin scenarios as web steps but through the JSON API.

### Authentication

Authenticate using OAuth tokens from [fixtures](../spec/fixtures/oauth_access_tokens.yml):

```ruby
step "I have logged in as Alice" do
  @alice = users(:alice)
  @auth = auth_header(oauth_access_tokens(:alice))
end
```

The `auth_header` helper accepts a token fixture and returns `{"Authorization" => "Bearer ALICE123"}`.

### Making requests

Use `get`, `post`, `patch` with the API path helpers and Bearer token headers:

```ruby
get api_v1_conversations_path, headers: @auth
data = JSON.parse(response.body)

post api_v1_conversations_path,
  params: {conversation: {subject: "Hello", recipient_id: bob.id}},
  headers: @auth

patch api_v1_task_assignment_path(task),
  params: {assignee_id: bob.id},
  headers: @auth
```

### Acting as another user

Use a different token to act as another user:

```ruby
bob_auth = auth_header(oauth_access_tokens(:bob))
post api_v1_conversation_acceptance_path(conversation), headers: bob_auth
```

### Dashboard/visual steps

Steps that assert visual state (status matrix colours, CSS classes) are no-ops in API mode:

```ruby
step "I should see a task summary on the dashboard" do
  # Visual — not relevant for API
end
```

### Shared steps and fixtures

The shared steps module (`spec/features/steps/task_steps.rb`) declares fixtures for both web and API modes:

```ruby
module TaskSteps
  def self.included(base)
    base.fixtures :users, :user_sessions, :user_identities, :oauth_applications, :oauth_access_tokens
  end
end
```

OAuth fixtures use `ActiveRecord::FixtureSet.identify` for IDs and declare `model_class` for Doorkeeper models:

```yaml
# spec/fixtures/oauth_access_tokens.yml
_fixture:
  model_class: Doorkeeper::AccessToken

alice:
  application_id: <%= ActiveRecord::FixtureSet.identify(:test_client) %>
  resource_owner_id: <%= ActiveRecord::FixtureSet.identify(:alice) %>
  token: ALICE123
```

## API Request Specs (rspec-openapi)

API request specs under `spec/requests/api/v1/` describe each endpoint and generate OpenAPI documentation via [rspec-openapi](https://github.com/exoego/rspec-openapi).

### Writing API request specs

```ruby
RSpec.describe "API V1 Users", type: :request do
  fixtures :users, :oauth_applications, :oauth_access_tokens

  let(:headers) { {"Authorization" => "Bearer ALICE123"} }

  describe "GET /api/v1/users" do
    it "returns the list of users" do
      get api_v1_users_path, headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data.map { _1["uid"] }).to include("alice")
    end
  end
end
```

### Generating OpenAPI documentation

```bash
OPENAPI=1 bundle exec rspec spec/requests/api/
```

This produces an OpenAPI 3.0 schema from the request/response pairs in the specs.

### Running the tests

```bash
# Web features (Rack::Test)
TEST_INTERFACE=web bundle exec rspec spec/features/

# API features (HTTP with Bearer tokens)
TEST_INTERFACE=api bundle exec rspec spec/features/

# API request specs (for OpenAPI generation)
bundle exec rspec spec/requests/api/

# Full suite
bundle exec rspec
```

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

## Turbo Broadcasts and Action Cable

### Broadcasting model changes

Use [`Turbo::Broadcastable`](https://www.rubydoc.info/github/hotwired/turbo-rails/Turbo/Broadcastable) to push updates to connected browsers.

There are two types of refresh: page refreshes and component refreshes.  

**Page Refreshes**

```ruby
class Conversation < ApplicationRecord
  include Turbo::Broadcastable
  broadcasts_refreshes
end

class Message < ApplicationRecord
  include Turbo::Broadcastable
  broadcasts_refreshes_to :conversation
end
```

Whenever a Conversation or Message is updated, a Turbo broadcast is sent.  Any view that uses `turbo_stream_from @conversation` will receive the broadcast and trigger a full page reload (Turbo uses page morphing to minimise the screen redraw).  This allows for very simple automated updates of pages - but care must be taken to ensure that the page refresh does not disrupt the user (for example, if they are in the middle of typing into a form and the page redraws).

**Component Refreshes**

```ruby
class User < ApplicationRecord 
  include Turbo::Broadcastable
  include ActionView::RecordIdentifier
  after_update_commit :redraw_status_badge, if: -> { saved_change_to? :status_badge }
  
  private def redraw_status_badge
    broadcast_update_later_to "user_status_badges", target: dom_id(self, :status_badge), renderable: Components::UserStatusBadge.new(user: self)
  end 
end
```
Whenever the User's `status_badge` field is updated, a Turbo broadcast is sent.  Any view that uses `turbo_stream_from "user_status_badges"` will receive the broadcast.  It then searches for an element with the ID `dom_id(@user, :status_badge)` (which resolves to "status_badge_user_123") and replaces the inner HTML with the rendered content.  

### When to use which type of refresh

Prefer page refreshes unless the view contains form fields (where the user may be typing when the refresh arrives) or if the update affects only a tiny part of the page's function.

**Page refresh advantages:**

- Simple — views express an interest in a model and the model updates them without any dependencies between model and view
- Auth-aware — the page is reloaded by the browser using the current session and cookies, so the redraw respects the user's permissions

**Page refresh disadvantages:**

- Redraw — potentially loses any input fields that are partially completed
- Expensive — 100 logged-in users will trigger 100 simultaneous page requests to the server

**Component refresh advantages:**

- Targeted — only individual components are updated, so minimal redrawing occurs

**Component refresh disadvantages:**

- Auth-unaware — the `renderable` is drawn in a background thread, outside of the request/response cycle, so it cannot vary the output based on the current user's permissions
- Mixes layers — the model layer requires knowledge of the view layer, breaking encapsulation

### Action Cable connection

The WebSocket connection authenticates via the session cookie in [app/channels/application_cable/connection.rb](../app/channels/application_cable/connection.rb). Use the fully qualified `User::Session` — bare `Session` is not resolved within the `ApplicationCable` module.

### Known limitation: async-cable and Puma

The project uses `async-cable` for WebSocket support, which requires Falcon's async event loop. Puma (used as the Capybara test server) cannot run the async-cable middleware. Tests cannot use live broadcasts.  

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
