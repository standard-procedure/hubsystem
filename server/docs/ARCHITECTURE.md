# Architecture

> **Note:** HubSystem is a mono-repo containing two applications: `server/` (this app — Rails hub) and `world/` (Async synthetic runtime). The pipeline architecture, LLM tiers, and synthetic internals described below belong to `world/`. See `world/AGENTS.md` for the full synthetic runtime architecture. This document covers the `server/` application only.

## Users

[Users](app/model/user.rb) access the system - humans will use [OmniAuth](config/initializers/omniauth.rb) (via [identities](app/model/user/identity.rb)) and synthetics will use OAuth2 Access Tokens (via the Doorkeeper gem).  

## Web user-interface

## API

JSON API under `/api/v1/` authenticated via [Doorkeeper](config/initializers/doorkeeper.rb) OAuth 2.0 Bearer tokens.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|

### Authentication

Include a Bearer token in the Authorization header:
```
Authorization: Bearer <token>
```

OpenAPI documentation is auto-generated from request specs via [rspec-openapi](https://github.com/exoego/rspec-openapi):
```bash
OPENAPI=1 bundle exec rspec spec/requests/api/
```

## Infrastructure

