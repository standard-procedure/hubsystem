# hubsystem-server — Agent Guide

This is the Rails API server for HubSystem.

**Parent project:** See `../AGENTS.md` for overall HubSystem architecture and design.

## Development Principles

This project follows strict test-driven development with dual web/API feature parity.

### Outside-In TDD with Dual Web/API Steps

All features must work via **both** web UI and API:

```
spec/features/
  ├── participants.feature          # Gherkin feature spec
  └── steps/
      ├── web/
      │   └── participants_steps.rb   # Web UI steps (Playwright)
      └── api/
          └── participants_steps.rb   # API steps (request specs)
```

**Example feature:**
```gherkin
Feature: Create participant
  Scenario: Via web UI
    Given I am logged in as an admin via web
    When I create a participant named "Alice" via web
    Then I should see "Alice" in the participants list via web
    
  Scenario: Via API
    Given I am authenticated as an admin via API
    When I create a participant named "Alice" via API
    Then the API should return the participant "Alice"
```

This proves feature parity — if the web UI works but the API doesn't (or vice versa), the specs fail!

### Core Principles (from template)

1. **Outside-In Development** — Feature specs → Request specs → Model specs
2. **Red/Green/Refactor** — Failing test first, always!
3. **Fixtures over factories** (DHH's fast approach)
4. **Seeds required** — Idempotent development data
5. **Browser testing** — Playwright via Turnip
6. **Type safety** — Literal gem with `lib/types.rb` helpers
7. **Documentation** — Keep `docs/` updated

### Testing Workflow

```bash
# 0. Check if inside/outside container
test -d /workspaces && echo "Inside ✅" || echo "Outside - use devcontainer exec"

# 1. Write feature spec (both web + API scenarios)
# spec/features/my_feature.feature

# 2. Write step definitions
# spec/features/steps/web/my_steps.rb
# spec/features/steps/api/my_steps.rb

# 3. Run specs (RED)
bundle exec rspec spec/features/my_feature.feature

# 4. Implement (controller, model, view component)

# 5. Run until green
bundle exec rspec

# 6. Lint
bundle exec standardrb --fix

# 7. Update OpenAPI
OPENAPI=1 bundle exec rspec spec/requests/
```

## Technology Stack

- **Backend:** Rails 8+, Ruby 3.4.5, PostgreSQL with pgvector
- **Frontend:** Phlex components, Hotwire, Tailwind CSS
- **JS Runtime:** Bun
- **Testing:** RSpec, Turnip, Playwright, Fixtures
- **Linting:** StandardRB
- **Type Safety:** Literal
- **Notifications:** Noticed (event-sourced)
- **Monitoring:** RailsPulse
- **API Docs:** rspec-openapi (auto-generated)


d## HubSystem-Specific Concepts

See `../docs/ARCHITECTURE.md` for full design.

---

**For complete development standards**, see the full AGENTS.md at the template root.
