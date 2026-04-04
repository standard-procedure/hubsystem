# Development Patterns

## Development Workflow

When building new features, follow this cycle:

### 1. Write the Gherkin scenario

Start with a `.feature` file in `spec/features/`. Define the user-facing behaviour before writing any implementation code.

### 2. Update fixtures AND seeds

**Fixtures** (`spec/fixtures/`) provide test data for RSpec. **Seeds** (`db/seeds.rb`) provide development data for the running app. Both must reflect the current data model. Seeds must be idempotent (`first_or_create!` pattern) so `rails db:seed` can be re-run safely.

When adding new models, associations, or test scenarios: update both fixtures and seeds in the same change.

### 3. Implement and run specs

Write step definitions, controllers, views, and models to make the scenarios pass. Run the full suite:

```bash
# Inside devcontainer
bin/rspec                                          # Full suite (web features + unit/request specs)
TEST_INTERFACE=api bin/rspec spec/features/         # API features only
TEST_INTERFACE=web bin/rspec spec/features/         # Web features only
bin/rspec spec/requests/api/                        # API request specs (for OpenAPI generation)
```

### 4. Evaluate UI with Playwright

After implementation, visually verify the UI using Playwright (via MCP or manually). The app runs at `http://localhost:3000` inside the devcontainer.

**Logging in via the developer strategy:**

1. Navigate to `http://localhost:3000` — redirects to the login page
2. Click "Developer login" — shows the OmniAuth developer form asking for a UID
3. Enter a UID from `db/seeds.rb` (e.g. `alice` for Alice Aardvark, `bob` for Bob Badger)
4. Click "Sign In" — logs in and redirects to the dashboard

The UID must match a `User::Identity` record with `provider: "developer"`. Seeds create identities for alice and bob.

### 5. Run `bin/ci`

Before considering a feature complete, run the full CI check:

```bash
# Inside devcontainer
bin/ci
```

This runs the complete pipeline defined in `config/ci.rb`: setup, style checks (StandardRB), security audits (bundler-audit, brakeman), and all specs. Critically, `bin/rails spec` **eager-loads all application code** before running tests — this catches autoloading issues (missing requires, constant resolution bugs) that `bin/rspec` misses because it loads files lazily on demand.

If `bin/ci` passes, the feature is ready for review.

### 6. Run a code review

After implementation, CI, and visual verification, review the code for:

- **Performance**: N+1 queries, in-memory loading of large collections, missing pagination
- **Security**: ILIKE wildcard escaping, mass assignment, authorization gaps
- **Consistency**: API response shapes, duplicated helpers, naming conventions
- **Error handling**: `ErrorHandlers::Api` and `ErrorHandlers::Web` catch common exceptions — check for unhandled edge cases

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
| Archive a conversation | `POST /conversations/:id/closure` | `ConversationClosuresController#create` |

### Why

- Each controller has a single responsibility
- Standard REST verbs — no custom actions like `PUT /conversations/:id/accept`
- Easy to add confirmation pages via `GET new`
- Clear authorisation boundaries per transition

## Main Navigation Pattern

`Components::MainNavigation` ([app/components/main_navigation.rb](../app/components/main_navigation.rb)) is the single source of truth for the application's top-level navigation. It holds the ordered list of locations and provides iterators used by both `CrtMonitor` (the navigation buttons on the bottom bezel) and `NavigationPanel` (the side-rail inside the screen).

### LOCATIONS

```ruby
Components::MainNavigation::LOCATIONS = {
  dashboard: :root_path,
  messages:  :messages_path,
  projects:  :root_path,
  terminals: :root_path,
  settings:  :root_path,
}.freeze
```

Keys are `Symbol` names; values are route helper method names.

### Iterating over locations

```ruby
Components::MainNavigation.each active: :messages, alerts: [:projects] do |name:, label:, href:, status:|
  # name   — Symbol key  (:dashboard, :messages, …)
  # label  — I18n string ("Dashboard", "Messages", …)
  # href   — resolved URL string
  # status — :active | :alert | :nominal
end
```

`status` is `:active` when `name == active`, `:alert` when `name` is in `alerts`, otherwise `:nominal`.

### Type constraints

The module exposes two type-constraint methods used by component props:

```ruby
prop :active, Components::MainNavigation.Location   # OneOf(LOCATIONS.keys) — a single symbol
prop :alerts, Components::MainNavigation.Locations  # SomeOf(*LOCATIONS.keys) — an array of symbols
```

### Adding a new location

1. Add an entry to `LOCATIONS` in `main_navigation.rb`
2. Add a route helper for it in `config/routes.rb`
3. Add an I18n key `application.<name>` in `config/locales/en.yml` (run `yaml-sort -i config/locales/*.yml` afterwards)

### CrtMonitor and NavigationPanel

`CrtMonitor` accepts `active:` and `alerts:` props and passes them both to the bottom bezel buttons and to `NavigationPanel`:

```ruby
Components::CrtMonitor.new(active: :messages, alerts: [:projects])
```

`NavigationPanel` renders the side rail inside the screen and also accepts `active:` and `alerts:`.

## Internationalisation

All user-visible strings must go through I18n. Never hardcode display text in components or views.

### Always use `t()`

```ruby
# In a Phlex component (Components::Base includes Phlex::Rails::Helpers::T)
t("application.logout")      # => "Power"
t("views.dashboard.show.unread_messages", count: 3)
```

### Key conventions

Top-level keys under `en:`:

| Namespace | Purpose |
|-----------|---------|
| `application.*` | Shared UI labels (navigation, actions, titles) |
| `views.<controller>.<action>.*` | Strings specific to a single view |

### Adding new strings

1. Add the key to `config/locales/en.yml`
2. Run `yaml-sort -i config/locales/en.yml` to keep the file alphabetically sorted
3. Reference via `t("...")` — never interpolate raw strings into templates

## Type Safety

HubSystem uses [Literal](https://literal.fun) for typed component props, with project-specific extensions.

### Literal built-in types

Common types available in any `Phlex::HTML` subclass (via `extend Literal::Properties`):

```ruby
prop :name,     String              # required String
prop :label,    _String?            # nilable String
prop :count,    Integer, default: 0 # Integer with default
prop :active,   _Boolean            # true or false
prop :callback, _Callable           # anything that responds to #call
prop :anything, _Any?               # unconstrained, nilable
```

See [Literal's built-in types](https://literal.fun/docs/built-in-types.html) for the full list.

### Components::Types — project extensions

`Components::Types` (included in `Components::Base`) adds two constraint builders:

```ruby
prop :size,    OneOf(:sm, :md, :lg)               # exactly one of these symbols
prop :targets, SomeOf(:users, :groups, :bots)     # an array containing only these symbols
```

`OneOf` and `SomeOf` return procs used with `===` — they work as Literal type constraints and also with `_check`.

### HasTypeChecks — runtime assertions

`HasTypeChecks` provides `_check` for validating values at module boundaries:

```ruby
include HasTypeChecks

def self.some_method(value, kind:)
  _check value, is: _String?       # nilable string
  _check kind,  is: OneOf(:a, :b)  # symbol constraint
end
```

Use `_check` in module-level methods and service objects, especially when accepting values from external callers. Component props are already validated by Literal on initialisation.

## Status Displays

Status is represented as a coloured dot (`.status-dot`) paired with a label. Two components handle this.

### StatusItem

A single dot + label:

```ruby
Components::StatusItem.new(state: :online, label: "Alice")
Components::StatusItem.new(state: :alert) { "Bob (unread)" }
```

| state | colour |
|-------|--------|
| `:offline` | dark (grey) |
| `:online` | green |
| `:alert` | blue (cryo) |
| `:warning` | amber |
| `:critical` | red |

### StatusBar

Groups multiple status items with a builder API:

```ruby
render Components::StatusBar.new do |bar|
  bar.item state: :online,  label: "Alice"
  bar.item state: :warning, label: "Bob"
  bar.item state: :alert  do
    a(href: inbox_path) { "Charlie (3 unread)" }
  end
end
```

### HasStatusBadge

The `HasStatusBadge` concern adds a `status_badge` enum to any model:

```ruby
include HasStatusBadge
# Adds: enum :status_badge, offline: 0, online: 10, alert: 20, warning: 30, critical: 50
```

Rails enums return strings (e.g. `"online"`). When passing to a Literal/Phlex prop that expects a symbol, call `.to_sym`:

```ruby
StatusItem(state: user.status_badge.to_sym)
```

## CSS Classes as Arrays in Phlex

Phlex accepts an `Array` for the `class:` attribute — it compacts the array and joins with spaces. Use this for conditional classes:

```ruby
a href: href,
  class: [
    "crt-button",
    ("crt-button--active" if active),
    ("crt-button--alert"  if alert),
  ]
```

`nil` entries (from false conditions) are dropped automatically. No ternaries or string interpolation needed.

### mix helper

When merging caller-supplied classes with component defaults, use `mix`:

```ruby
div(mix({ class: "status-bar" }, @html_attrs))
```

`mix` concatenates `class` values rather than overwriting them. Use the bang form (`class!:`) to force-override instead of merge.

## Error Handling

`ErrorHandlers` (`app/controllers/concerns/error_handlers.rb`) provides centralised error handling for both web and API controllers.

### ErrorHandlers::Api

Included in `Api::V1::BaseController`. Renders JSON responses for:

| Exception | Status | Response |
|-----------|--------|----------|
| `ActiveRecord::RecordNotFound` | 404 | `{error: "not_found"}` |
| `ActiveRecord::RecordInvalid` | 422 | `{error: "invalid_data", errors: [...]}` |
| `ArgumentError` | 400 | `{error: "bad_request", message: "..."}` |
| `StandardError` (production only) | 500 | `{error: "...", message: "..."}` |

### ErrorHandlers::Web

Included in `ApplicationController`. Redirects with flash alerts for:

| Exception | Behaviour |
|-----------|-----------|
| `ActiveRecord::RecordNotFound` | Redirect to root with "Not found" alert |
| `StandardError` (production only) | Redirect to root with generic alert |

Individual controllers can still rescue specific exceptions for custom behaviour (e.g. re-rendering a form on validation failure).

## Concerns and Background Jobs Organisation

### Cross-cutting concerns

Concerns that apply to many models live in `app/models/concerns/`:

- `HasStatusBadge` — adds `status_badge` enum
- `HasTags` — tagging support
- `HasAttachments` — Active Storage attachments
- `HasEmbeddings` — pgvector embedding generation
- `HasTypeChecks` — runtime type assertion helper

### Background jobs nested inside concerns

When a job is tightly coupled to one concern and has no use outside it, nest the job class inside the concern:

```ruby
module HasEmbeddings
  extend ActiveSupport::Concern
  # … concern logic …

  class GenerateEmbedding < ApplicationJob
    def perform(object)
      _check object, is: HasEmbeddings
      object.update_columns embedding: Embedding.new(text: object.embeddable_text).vectors
    end
  end
end
```

This keeps the job co-located with the behaviour that triggers it. Jobs with broader use (e.g. sending emails) live in `app/jobs/` as usual.

### Model-specific concerns

Concerns used by only one model can live alongside it or inline in the model file. Prefer a separate file only if the concern is large enough to warrant it.
