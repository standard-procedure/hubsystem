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

### Navigation

Use the CRT Monitor knobs (identified by `title` attribute) and in-page links:

```ruby
find("a[title='Dashboard']").click    # CRT Monitor nav knob
find("a[title='Messages']").click     # CRT Monitor nav knob
click_on "Archived"                   # In-page nav item
click_on "New Conversation"           # In-page button/link
click_on "Catch up"                   # Conversation link by subject text
```

On the dashboard, conversations appear as status matrix cells without text. Click them by href:

```ruby
find("a.matrix-cell[href='#{conversation_path(conversation)}']").click
```

### Forms

Use `fill_in` for text fields and `find("label", text: "...").click` for radio buttons styled as buttons:

```ruby
find("label", text: "Bob Badger").click
fill_in "conversation[subject]", with: "Hi Bob"
click_on "Send Request"
```

### Simulating other users

When another user acts (e.g. Bob accepts a request), update the model directly. Then use `wait_until` before navigating to see the result:

```ruby
# Bob acts in the background
conversation.update!(status: :active)

# Alice navigates to see the change
wait_until { conversation.reload.active? }
find("a[title='Messages']").click
click_on conversation.subject
```

`wait_until` (from `spec/support/wait.rb`) polls a condition block until it returns truthy, with a 20-second timeout.

### What NOT to do

- Do not use `visit` after the initial login — click through the UI instead
- Do not check model state as a substitute for asserting what the page shows
- Do not use `page.driver` or other Capybara internals

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
