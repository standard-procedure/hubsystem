# HubSystem — Guide for Agents

This repository contains two separate applications that together form HubSystem: a multi-user collaboration platform where participants are human or synthetic (AI).

## Repository Structure

```
hubsystem/
  server/    Rails application — the hub (conversations, API, knowledge base)
  world/     Ruby/Async application — the synthetic runtime
  CLAUDE.md  this file
```

**The two applications communicate exclusively via HTTP/WebSocket. They share no database and no process space.** Do not introduce direct dependencies between them.

## server/

See `server/CLAUDE.md` for full details.

The Rails hub application. Humans use the web UI. Synthetics use the JSON API. Key concerns: conversations, messages, shared knowledge base (pgvector RAG), task database, auth tokens, Governor event log, WebSocket publishing feed.

**Never add synthetic runtime logic here.** The Rails app has no knowledge of how a Synthetic works internally.

## world/

See `world/CLAUDE.md` for full details.

The synthetic runtime. A minimal Rails environment (no web server, no routes, no views) running long-lived Synthetic processes supervised by `async-service`. Synthetics communicate with `server/` exclusively via the HubSystem JSON API and WebSocket.

**Never add web-serving, routing, or view logic here.**

## Ideas and Notes

`docs/IDEAS.md` — scratch pad for ideas and things to revisit. Add entries there rather than letting them get lost.

## Running Scripts

This project runs inside a devcontainer. If you need to execute scripts (tests, generators, migrations, etc.) you must run them inside the container, not on the host.

Use the `devsh` alias (or the full form) to get a shell:

```
devcontainer exec --workspace-folder . bash -l
```

Or run a command directly:

```
devcontainer exec --workspace-folder . bash -lc "cd server && bin/rails db:migrate"
```

Both `server/` and `world/` are available under `/workspaces/hubsystem/` inside the container.

### Ruby and mise

Ruby is managed by [mise](https://mise.jdx.dev/) and is **not on PATH in non-login shells**. The `-l` flag is required when running `bash` so that mise activates correctly.

If a login shell is not an option (e.g. a raw `devcontainer exec` without `-l`), invoke Ruby by its full path:

```
/home/vscode/.local/share/mise/installs/ruby/$(cat .ruby-version)/bin/ruby
```

Or use `mise exec` to activate it explicitly:

```
devcontainer exec --workspace-folder . bash -c "mise exec -- ruby bin/rspec"
```

Always prefer the login shell form (`bash -l`) — it is simpler and picks up the correct Ruby version automatically.

### Running from the host via docker exec

`devcontainer exec` with `bash -l` may not activate mise when invoked from the host (the login profile doesn't fire). If that happens, use `docker exec` directly and prepend mise's bin directory to PATH explicitly:

```
docker exec -u vscode hubsystem-dev-1 bash -c \
  "export PATH=\"/home/vscode/.local/bin:\$PATH\" && cd /workspaces/hubsystem/server && mise exec -- bin/rspec"
```

The container name is `hubsystem-dev-1` (verify with `docker ps`). The `mise exec --` prefix activates the correct Ruby version before running the command.

## Shared Conventions

- Ruby version: managed by mise, see `.ruby-version`
- Tests: RSpec throughout, Turnip/Gherkin + Capybara for outside-in in `server/`
- Development: devcontainer-based workflow
- Outside-in BDD: start from the user's perspective, work inwards
- YAGNI: resist adding complexity until it is needed