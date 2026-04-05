# core/ — HubSystem Engine

## What this is

A Rails engine providing shared infrastructure for all HubSystem applications (`server/` and `world/`). Contains the command pattern, type checking, and (future) security passes.

Both applications depend on this engine: `gem "hub_system", path: "../core"`.

## Key concepts

### Commands (`HubSystem::HasCommands`)

Every action in HubSystem — human or synthetic — is modelled as a command. Commands provide an action registry, audit trail, and type-safe DSL.

```ruby
class Project < ApplicationRecord
  include HubSystem::HasCommands

  command :add_document do
    description "Add a document to this project"
    param :project, Project
    param :document, Document
    authorisation { |user| user.has_unlocked_security_pass_for?(:add_document, on: project) }
    returns Document
    raises Project::DocumentCannotBeAdded

    def call(project:, document:)
      raise Project::DocumentCannotBeAdded unless project.accepts_documents?
      project.documents << document
      document
    end
  end
end
```

The `command` macro:
1. Captures DSL declarations (`description`, `param`, `authorisation`, `returns`, `raises`) and the `def call` method from a single block
2. Creates a named constant on the model (e.g. `Project::AddDocument`) with class-level metadata
3. Registers in the model's command catalogue (`Project.commands`)
4. Defines an instance method that delegates to `HubSystem::Command.call` with logging

#### Using commands

```ruby
# Via instance method (passes self as the model param automatically):
project.add_document(actor: current_user, document: document)

# Catalogue access:
Project.commands                     # => {add_document: <CommandDefinition>, ...}
Project::AddDocument.description     # => "Add a document to this project"
Project::AddDocument.params_metadata # => {project: Project, document: Document}
Project::AddDocument.return_types    # => [Document]
Project::AddDocument.exception_types # => [Project::DocumentCannotBeAdded]
Project::AddDocument.authorised?(user) # => true/false
```

#### Authorisation

The `authorisation` block receives the acting user and returns true/false. **Defaults to false** (fail closed). Every command must explicitly declare who can run it.

#### Audit trail

`HubSystem::Command.call` creates a `HubSystem::CommandLogEntry` before execution (so the record exists even if the process crashes), then updates it on completion or failure:

```
command_class: "Project::AddDocument"
actor:         User#1 (polymorphic)
params:        {project: {class: "Project", id: 1}, document: {class: "Document", id: 2}}
status:        started → completed | failed
result:        "Document#2"
error:         "RuntimeError: something broke" (on failure)
```

### CommandDefinition (`HubSystem::CommandDefinition`)

An immutable `Literal::Object` holding the metadata for a registered command. Created by `CommandDefinition::Builder` which evaluates the DSL block, then frozen into the definition.

### HasTypeChecks (`HubSystem::HasTypeChecks`)

Runtime type assertions using `===` pattern matching:

```ruby
include HubSystem::HasTypeChecks

_check value, is: String        # passes
_check 42, is: String           # raises ArgumentError
_check value, is: proc { _1 > 0 } # custom constraint
```

Available as both class and instance method.

## Key directories

```
core/
  app/models/
    hub_system/
      application_record.rb     Base AR class for engine models
      command.rb                Command runner (call, authorise, log)
      command_definition.rb     Literal::Object for command metadata + Builder
      command_log_entry.rb      ActiveRecord audit trail
    concerns/hub_system/
      has_commands.rb           The command DSL macro
      has_type_checks.rb        Runtime type assertions
  db/migrate/                   Engine migrations (auto-loaded by host apps)
  lib/hub_system/engine.rb      Rails::Engine with isolated namespace
  spec/                         RSpec tests with SQLite test_app
```

## Testing

```bash
cd core/
bin/rails db:create db:migrate db:test:prepare  # first time
bin/rails spec                                   # full suite
bin/rspec spec/path/to/file_spec.rb              # single file
```

Uses a minimal Rails app in `spec/test_app/` with SQLite. Test models (`Widget`, `User`) exercise the DSL.

## Future additions

- **SecurityPass** — capability-based access control (`BasicSecurityPass`, `AdvancedSecurityPass`)
- **SecureResource** — concern for models protected by security passes
- **HasGovernor** — safety checks on command execution
- **Dynamic API generation** — automatic controllers from command catalogues
- **LLM tool adapter** — maps command catalogue to LLM function calling schemas

## What does NOT belong here

- Application-specific models (conversations, messages, tasks) — those live in `server/`
- Synthetic runtime logic (SynthRunner, emotional processing) — those live in `world/`
- UI components — those live in `server/`
