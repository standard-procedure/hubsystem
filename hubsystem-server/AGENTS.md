# hubsystem-server — Agent Guide

This is the Rails API server for HubSystem.

**Parent project:** See `../AGENTS.md` for overall HubSystem architecture and design.

## Development Principles

This project follows strict test-driven development with dual web/API feature parity.

See `docs/DEVELOPMENT-PROCESS.md`

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

## User Interface 

The design system is called [mother](../docs/hubsystem-design-system-reference.html) implemented in `app/assets/mother.css`.  It is designed to look like the computers from the 1980s Aliens films.  

## Phlex Components

This project uses **Phlex** (not ERB) for all HTML rendering. See [`docs/PHLEX-GUIDE.md`](docs/PHLEX-GUIDE.md) for the full guide covering components, views, layouts, attributes, yielding, kits, Literal properties, testing, and Rails integration.

## HubSystem-Specific Concepts

See `../docs/ARCHITECTURE.md` for full design.

---

**For complete development standards**, see the full AGENTS.md at the template root.
