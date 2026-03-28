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
