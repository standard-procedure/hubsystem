# Phase 4 — Seeds + Dart CLI Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add development seeds (named agents + human) and a Dart CLI for interacting with the HubSystem API from the terminal.

**Architecture:** Two independent subsystems — (1) Rails seed data + two new API endpoints (inbox, conversations via participant_slugs), and (2) a new Dart 3.x CLI project in `hubsystem-cli/` with four commands. The Rails additions are TDD; the Dart CLI is written without running (Dart may not be installed).

**Tech Stack:** Ruby on Rails 8.1, RSpec, Faker gem; Dart 3.x, args package, http package.

---

## File Map

### Rails (hubsystem-server/)

| Action | File |
|--------|------|
| Modify | `Gemfile` — add faker to development group |
| Create | `db/seeds/development.rb` — 5 agents + Baz + group + security passes |
| Modify | `app/controllers/messages_controller.rb` — add `inbox` action, `from` object in JSON, slug/id lookup |
| Modify | `app/controllers/conversations_controller.rb` — accept `participant_slugs` + `initial_message` |
| Modify | `config/routes.rb` — add `GET /messages/inbox` |
| Create | `spec/requests/messages_inbox_spec.rb` — inbox endpoint specs |
| Modify | `spec/requests/conversations_spec.rb` — add specs for new participant_slugs interface |

### Dart CLI (hubsystem-cli/) — all new

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Package config, deps: args ^2.4.0, http ^1.2.0 |
| `bin/hubsystem.dart` | Entry point, env var check, CommandRunner wiring |
| `lib/api_client.dart` | Thin HTTP wrapper (reusable in Flutter) |
| `lib/commands/participants.dart` | `hubsystem participants` |
| `lib/commands/send_message.dart` | `hubsystem send --to=X --message=Y` |
| `lib/commands/inbox.dart` | `hubsystem inbox` |
| `lib/commands/conversation.dart` | `hubsystem convo --with=X` / `--id=N` |
| `README.md` | Build instructions, usage |

---

## Task 1: Add Faker Gem + Development Seeds

**Files:**
- Modify: `hubsystem-server/Gemfile`
- Create: `hubsystem-server/db/seeds/development.rb`

- [ ] **Step 1: Add faker to Gemfile**

In `hubsystem-server/Gemfile`, add to the `group :development, :test do` block:

```ruby
gem "faker"
```

- [ ] **Step 2: Create db/seeds/development.rb**

Create `hubsystem-server/db/seeds/development.rb` with exactly this content:

```ruby
# 5-8 named agents with distinct personalities and agent classes
agents = [
  { name: "Aria",  slug: "aria",  agent_class: "SupportAgent",   description: "Warm and patient. Specialises in helping humans navigate complex situations. Likes: clear questions, people who say thank you. Dislikes: vague requests." },
  { name: "Rex",   slug: "rex",   agent_class: "SecurityAgent",  description: "Precise and cautious. Takes security seriously but not humourlessly. Likes: well-specified permissions. Dislikes: corner-cutting." },
  { name: "Nova",  slug: "nova",  agent_class: "ResearchAgent",  description: "Curious and thorough. Loves diving deep into topics. Likes: interesting problems, citations. Dislikes: being rushed." },
  { name: "Clio",  slug: "clio",  agent_class: "MemoryAgent",    description: "Quiet and methodical. Excellent at finding patterns across conversations. Likes: well-tagged memories. Dislikes: ambiguous context." },
  { name: "Dex",   slug: "dex",   agent_class: "DevAgent",       description: "Pragmatic and fast. Writes scripts first, asks questions later. Likes: bash, working code. Dislikes: meetings." },
]

agents.each do |attrs|
  AgentParticipant.find_or_create_by!(slug: attrs[:slug]) do |a|
    a.name = attrs[:name]
    a.agent_class = attrs[:agent_class]
    a.description = attrs[:description]
  end
end

# Human participant for Baz
baz = HumanParticipant.find_or_create_by!(slug: "baz") do |h|
  h.name = "Baz"
  h.description = "The developer. Curious, direct, occasionally impatient."
end

# Default group — everyone can message everyone
group = Group.find_or_create_by!(slug: "default") do |g|
  g.name = "Default"
  g.group_type = "account"
end

# Security passes for all
Participant.all.each do |p|
  SecurityPass.find_or_create_by!(participant: p, group: group) do |sp|
    sp.capabilities = ["message"]
  end
end

# Give Dex bash capability (find_or_create won't update existing — handle separately)
dex = AgentParticipant.find_by!(slug: "dex")
dex_pass = SecurityPass.find_or_initialize_by(participant: dex, group: group)
dex_pass.capabilities = ["message", "bash"]
dex_pass.save!

puts ""
puts "=== HubSystem Development Seeds ==="
puts ""
puts "Agents: #{AgentParticipant.pluck(:name).join(', ')}"
puts ""
puts "Your token (Baz):"
puts "  export HUBSYSTEM_TOKEN=#{baz.token}"
puts "  export HUBSYSTEM_URL=http://localhost:3000"
puts ""
puts "Try: hubsystem participants"
puts "     hubsystem send --to=aria --message='Hello Aria'"
puts "     hubsystem inbox"
puts ""
```

- [ ] **Step 3: Verify seeds.rb routing**

Confirm `hubsystem-server/db/seeds.rb` already routes correctly (it should already do this from Phase 3):

```ruby
seed_file = Rails.root.join("db/seeds/#{Rails.env}.rb")
load seed_file if seed_file.exist?
```

If it doesn't, add it.

- [ ] **Step 4: Commit seeds**

```bash
cd hubsystem-server && git add Gemfile db/seeds/development.rb
git commit -m "feat: development seeds (Aria, Rex, Nova, Clio, Dex + Baz)"
```

---

## Task 2: GET /messages/inbox Endpoint

**Files:**
- Create: `hubsystem-server/spec/requests/messages_inbox_spec.rb`
- Modify: `hubsystem-server/config/routes.rb`
- Modify: `hubsystem-server/app/controllers/messages_controller.rb`

- [ ] **Step 1: Write the failing spec**

Create `hubsystem-server/spec/requests/messages_inbox_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Messages inbox", type: :request do
  let(:me)     { create(:human_participant) }
  let(:sender) { create(:human_participant) }

  before do
    msg = create(:message, from: sender, to: me, subject: "Hello")
    msg.parts.destroy_all
    create(:message_part, message: msg, content_type: "text/plain", body: "Hey there", position: 0)
  end

  describe "GET /messages/inbox" do
    context "with valid token" do
      it "returns messages addressed to the current participant" do
        get "/messages/inbox", headers: { "X-Hub-Token" => me.token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["subject"]).to eq("Hello")
        expect(json.first["from"]["name"]).to eq(sender.name)
        expect(json.first["parts"].first["body"]).to eq("Hey there")
      end

      it "does not return messages sent to other participants" do
        other = create(:human_participant)
        create(:message, from: sender, to: other)

        get "/messages/inbox", headers: { "X-Hub-Token" => me.token }

        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end
    end

    context "without token" do
      it "returns 401" do
        get "/messages/inbox"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

- [ ] **Step 2: Run the spec to confirm it fails**

```bash
cd hubsystem-server && bin/rspec spec/requests/messages_inbox_spec.rb
```

Expected: routing error or 404 (route not defined yet).

- [ ] **Step 3: Add route**

In `hubsystem-server/config/routes.rb`, add the inbox route:

```ruby
Rails.application.routes.draw do
  resources :participants, only: [:index, :show] do
    resources :messages, only: [:create, :index]
  end

  resources :conversations, only: [:create] do
    get :messages, on: :member
  end

  namespace :messages do
    get :inbox, to: "messages#inbox"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

Wait — `namespace :messages` would conflict with the messages controller name. Use a direct route instead:

```ruby
Rails.application.routes.draw do
  resources :participants, only: [:index, :show] do
    resources :messages, only: [:create, :index]
  end

  resources :conversations, only: [:create] do
    get :messages, on: :member
  end

  get "/messages/inbox", to: "messages#inbox"

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 4: Add inbox action + update message_json to include from**

In `hubsystem-server/app/controllers/messages_controller.rb`:

1. Add the `inbox` action after the existing `index` action:

```ruby
def inbox
  messages = @current_participant.inbox_messages.includes(:parts, :from)
  render json: messages.map { |m| message_json(m) }
end
```

2. Update `message_json` to include the `from` object (keep `from_id` for backward compat):

```ruby
def message_json(message)
  {
    id: message.id,
    subject: message.subject,
    from_id: message.from_id,
    from: message.from ? { id: message.from.id, name: message.from.name } : nil,
    to_id: message.to_id,
    conversation_id: message.conversation_id,
    parts: message.parts.map { |p|
      {
        id: p.id,
        content_type: p.content_type,
        body: p.body,
        channel_hint: p.channel_hint,
        position: p.position
      }
    }
  }
end
```

- [ ] **Step 5: Run the spec to confirm it passes**

```bash
cd hubsystem-server && bin/rspec spec/requests/messages_inbox_spec.rb
```

Expected: all green.

- [ ] **Step 6: Run the full spec suite to confirm nothing broke**

```bash
cd hubsystem-server && bin/rspec
```

Expected: all green.

- [ ] **Step 7: Commit**

```bash
cd hubsystem-server && git add config/routes.rb app/controllers/messages_controller.rb spec/requests/messages_inbox_spec.rb
git commit -m "feat: GET /messages/inbox endpoint"
```

---

## Task 3: POST /conversations with participant_slugs + initial_message

**Files:**
- Modify: `hubsystem-server/app/controllers/conversations_controller.rb`
- Modify: `hubsystem-server/spec/requests/conversations_spec.rb`

The CLI sends:
```json
{
  "conversation": {
    "subject": "Hello",
    "participant_slugs": ["aria"],
    "initial_message": "Hi there"
  }
}
```

The controller needs to handle this new format alongside the existing format (so existing specs keep passing).

- [ ] **Step 1: Add new-format specs to conversations_spec.rb**

Add a new context block in the `POST /conversations` describe block in `spec/requests/conversations_spec.rb`:

```ruby
context "with participant_slugs format (CLI format)" do
  let(:agent) { create(:agent_participant, slug: "aria") }

  let(:slug_params) do
    {
      conversation: {
        subject: "Hello from CLI",
        participant_slugs: [agent.slug],
        initial_message: "Hi there from CLI"
      }
    }
  end

  it "creates a conversation with the named participants and returns 201" do
    post "/conversations",
      params: slug_params,
      headers: { "X-Hub-Token" => sender.token }

    expect(response).to have_http_status(:created)
    json = JSON.parse(response.body)
    expect(json["subject"]).to eq("Hello from CLI")
    expect(json["id"]).to be_present
  end
end
```

- [ ] **Step 2: Run the spec to confirm it fails**

```bash
cd hubsystem-server && bin/rspec spec/requests/conversations_spec.rb
```

Expected: the new context fails (likely `to_id is required` error).

- [ ] **Step 3: Update ConversationsController#create**

Replace the `create` action in `hubsystem-server/app/controllers/conversations_controller.rb` to handle both the old `message.to_id` format and the new `participant_slugs` + `initial_message` format:

```ruby
def create
  conversation = Conversation.new(subject: conversation_params[:subject])

  if conversation_params[:participant_slugs].present?
    # CLI format: participant_slugs + initial_message
    recipients = Participant.where(slug: conversation_params[:participant_slugs])
    if recipients.empty?
      return render json: { error: "No participants found for given slugs" }, status: :unprocessable_entity
    end

    message = conversation.messages.build(
      from: @current_participant,
      to: recipients.first,
      subject: conversation_params[:subject]
    )
    message.parts.build(
      content_type: "text/plain",
      body: conversation_params[:initial_message] || "",
      position: 0
    )

    conversation.conversation_memberships.build(participant: @current_participant)
    recipients.each do |recipient|
      conversation.conversation_memberships.build(participant: recipient) unless recipient == @current_participant
    end
  else
    # Original format: message.to_id + parts
    message_attrs = conversation_params[:message]
    parts_attrs = message_attrs&.dig(:parts) || []

    message = conversation.messages.build(
      from: @current_participant,
      subject: message_attrs&.dig(:subject)
    )

    to_participant = Participant.find_by(id: conversation_params.dig(:message, :to_id))
    return render json: { error: "to_id is required" }, status: :unprocessable_entity unless to_participant

    message.to = to_participant
    conversation.conversation_memberships.build(participant: @current_participant)
    conversation.conversation_memberships.build(participant: to_participant) unless to_participant == @current_participant

    parts_attrs.each_with_index do |part, index|
      message.parts.build(
        content_type: part[:content_type],
        body: part[:body],
        channel_hint: part[:channel_hint],
        position: index
      )
    end
  end

  if conversation.save
    render json: {
      id: conversation.id,
      subject: conversation.subject
    }, status: :created
  else
    render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
  end
end
```

Update `conversation_params` to permit the new fields:

```ruby
def conversation_params
  params.require(:conversation).permit(
    :subject,
    :initial_message,
    participant_slugs: [],
    message: [:subject, :to_id, parts: [:content_type, :body, :channel_hint]]
  )
end
```

- [ ] **Step 4: Run the spec to confirm it passes**

```bash
cd hubsystem-server && bin/rspec spec/requests/conversations_spec.rb
```

Expected: all green (both old and new format tests pass).

- [ ] **Step 5: Run full suite**

```bash
cd hubsystem-server && bin/rspec
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
cd hubsystem-server && git add app/controllers/conversations_controller.rb spec/requests/conversations_spec.rb
git commit -m "feat: POST /conversations accepts participant_slugs + initial_message"
```

---

## Task 4: Participant Slug Lookup in Messages

The CLI sends `POST /participants/aria/messages` (slug, not ID). The current controller uses `Participant.find(params[:participant_id])` which only works with numeric IDs.

**Files:**
- Modify: `hubsystem-server/app/controllers/messages_controller.rb`
- Modify: `hubsystem-server/spec/requests/messages_spec.rb`

- [ ] **Step 1: Add slug-based lookup spec**

Add a new context to `POST /participants/:participant_id/messages` in `spec/requests/messages_spec.rb`:

```ruby
context "when recipient is identified by slug" do
  let(:slugged_recipient) { create(:human_participant, slug: "baz") }

  it "accepts slug as participant_id and creates the message" do
    post "/participants/#{slugged_recipient.slug}/messages",
      params: valid_params,
      headers: { "X-Hub-Token" => sender.token }

    expect(response).to have_http_status(:created)
    json = JSON.parse(response.body)
    expect(json["to_id"]).to eq(slugged_recipient.id)
  end

  it "returns 404 for unknown slug" do
    post "/participants/nobody-here/messages",
      params: valid_params,
      headers: { "X-Hub-Token" => sender.token }

    expect(response).to have_http_status(:not_found)
  end
end
```

- [ ] **Step 2: Run the spec to confirm it fails**

```bash
cd hubsystem-server && bin/rspec spec/requests/messages_spec.rb
```

Expected: the slug test fails with ActiveRecord::RecordNotFound.

- [ ] **Step 3: Update MessagesController to find by slug or ID**

In `MessagesController`, update the `target` lookup in both `create` and `index` to handle slug:

Add a private helper and update the two find calls:

```ruby
def create
  target = find_participant(params[:participant_id])
  return render json: { error: "Participant not found" }, status: :not_found unless target
  # ... rest unchanged
end

def index
  target = find_participant(params[:participant_id])
  return render json: { error: "Participant not found" }, status: :not_found unless target
  # ... rest unchanged
end

private

def find_participant(id_or_slug)
  Participant.find_by(slug: id_or_slug) || Participant.find_by(id: id_or_slug)
end
```

Note: use `find_by` (not `find`) for the ID fallback to avoid raising `RecordNotFound` — we return a clean 404 JSON response instead.

- [ ] **Step 4: Run specs to confirm it passes**

```bash
cd hubsystem-server && bin/rspec spec/requests/messages_spec.rb
```

Expected: all green.

- [ ] **Step 5: Run full suite**

```bash
cd hubsystem-server && bin/rspec
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
cd hubsystem-server && git add app/controllers/messages_controller.rb spec/requests/messages_spec.rb
git commit -m "feat: participant messages lookup by slug or ID"
```

---

## Task 5: Dart CLI Scaffold

Note: Dart may not be installed. Write correct Dart 3.x code; no compile/run verification step.

**Files:** all new in `hubsystem-cli/`

- [ ] **Step 1: Create pubspec.yaml**

Create `hubsystem-cli/pubspec.yaml`:

```yaml
name: hubsystem
description: HubSystem CLI — send messages, read inbox, manage conversations
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  args: ^2.4.0
  http: ^1.2.0

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
```

- [ ] **Step 2: Create lib/api_client.dart**

Create `hubsystem-cli/lib/api_client.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final String token;

  ApiClient({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Hub-Token': token,
  };

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    _checkStatus(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'API error $statusCode: $body';
}
```

- [ ] **Step 3: Create lib/commands/participants.dart**

Create `hubsystem-cli/lib/commands/participants.dart`:

```dart
import 'package:args/command_runner.dart';
import '../api_client.dart';

class ParticipantsCommand extends Command<void> {
  @override final String name = 'participants';
  @override final String description = 'List participants in the directory';

  final ApiClient client;
  ParticipantsCommand(this.client);

  @override
  Future<void> run() async {
    final participants = await client.getList('/participants');
    if (participants.isEmpty) {
      print('No participants found.');
      return;
    }
    print('');
    print('  ${'NAME'.padRight(20)} ${'TYPE'.padRight(20)} SLUG');
    print('  ${'─' * 55}');
    for (final p in participants) {
      final name = (p['name'] as String? ?? 'Unknown').padRight(20);
      final type = ((p['type'] as String? ?? 'Unknown')).replaceAll('Participant', '').padRight(20);
      final slug = p['slug'] as String? ?? '?';
      print('  $name $type $slug');
    }
    print('');
  }
}
```

- [ ] **Step 4: Create lib/commands/send_message.dart**

Create `hubsystem-cli/lib/commands/send_message.dart`:

```dart
import 'package:args/command_runner.dart';
import '../api_client.dart';

class SendMessageCommand extends Command<void> {
  @override final String name = 'send';
  @override final String description = 'Send a message to a participant';

  final ApiClient client;

  SendMessageCommand(this.client) {
    argParser
      ..addOption('to', abbr: 't', mandatory: true, help: 'Recipient slug or ID')
      ..addOption('message', abbr: 'm', mandatory: true, help: 'Message body')
      ..addOption('subject', abbr: 's', help: 'Optional subject');
  }

  @override
  Future<void> run() async {
    final to = argResults!['to'] as String;
    final body = argResults!['message'] as String;
    final subject = argResults!['subject'] as String?;

    final payload = {
      'message': {
        'parts': [{'content_type': 'text/plain', 'body': body}],
        if (subject != null) 'subject': subject,
      }
    };

    await client.post('/participants/$to/messages', payload);
    print('✓ Message sent to $to');
  }
}
```

- [ ] **Step 5: Create lib/commands/inbox.dart**

Create `hubsystem-cli/lib/commands/inbox.dart`:

```dart
import 'package:args/command_runner.dart';
import '../api_client.dart';

class InboxCommand extends Command<void> {
  @override final String name = 'inbox';
  @override final String description = 'Read your inbox';

  final ApiClient client;
  InboxCommand(this.client);

  @override
  Future<void> run() async {
    final messages = await client.getList('/messages/inbox');

    if (messages.isEmpty) {
      print('Your inbox is empty.');
      return;
    }

    print('');
    for (final msg in messages) {
      final from = msg['from']?['name'] ?? 'Unknown';
      final subject = msg['subject'] ?? '(no subject)';
      final parts = msg['parts'] as List? ?? [];
      final body = parts.isNotEmpty ? parts.first['body'] ?? '' : '';

      print('From: $from');
      print('Subject: $subject');
      print('');
      print('  $body');
      print('');
      print('─' * 50);
      print('');
    }
  }
}
```

- [ ] **Step 6: Create lib/commands/conversation.dart**

Create `hubsystem-cli/lib/commands/conversation.dart`:

```dart
import 'package:args/command_runner.dart';
import '../api_client.dart';

class ConversationCommand extends Command<void> {
  @override final String name = 'convo';
  @override final String description = 'Start or read a conversation';

  final ApiClient client;

  ConversationCommand(this.client) {
    argParser
      ..addOption('with', abbr: 'w', help: 'Participant slug to start conversation with')
      ..addOption('subject', abbr: 's', help: 'Conversation subject')
      ..addOption('message', abbr: 'm', help: 'Opening message')
      ..addOption('id', abbr: 'i', help: 'Conversation ID to read');
  }

  @override
  Future<void> run() async {
    final id = argResults!['id'] as String?;

    if (id != null) {
      // Read existing conversation
      final messages = await client.getList('/conversations/$id/messages');
      print('');
      for (final msg in messages) {
        final from = msg['from']?['name'] ?? 'Unknown';
        final parts = msg['parts'] as List? ?? [];
        final body = parts.isNotEmpty ? parts.first['body'] ?? '' : '';
        print('[$from]: $body');
        print('');
      }
    } else {
      // Start new conversation
      final with_ = argResults!['with'] as String?;
      final subject = argResults!['subject'] as String? ?? 'Conversation';
      final message = argResults!['message'] as String? ?? 'Hello';

      if (with_ == null) {
        usageException('Either --with or --id is required');
      }

      final result = await client.post('/conversations', {
        'conversation': {
          'subject': subject,
          'participant_slugs': [with_],
          'initial_message': message,
        }
      });
      print('✓ Conversation started (ID: ${result['id']})');
      print('  Read with: hubsystem convo --id=${result['id']}');
    }
  }
}
```

- [ ] **Step 7: Create bin/hubsystem.dart**

Create `hubsystem-cli/bin/hubsystem.dart`:

```dart
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:hubsystem/commands/participants.dart';
import 'package:hubsystem/commands/send_message.dart';
import 'package:hubsystem/commands/inbox.dart';
import 'package:hubsystem/commands/conversation.dart';
import 'package:hubsystem/api_client.dart';

void main(List<String> args) async {
  final token = Platform.environment['HUBSYSTEM_TOKEN'];
  if (token == null || token.isEmpty) {
    stderr.writeln('Error: HUBSYSTEM_TOKEN environment variable is not set.');
    stderr.writeln('Run: export HUBSYSTEM_TOKEN=your-token');
    exit(1);
  }

  final baseUrl = Platform.environment['HUBSYSTEM_URL'] ?? 'http://localhost:3000';
  final client = ApiClient(baseUrl: baseUrl, token: token);

  final runner = CommandRunner<void>('hubsystem', 'HubSystem CLI')
    ..addCommand(ParticipantsCommand(client))
    ..addCommand(SendMessageCommand(client))
    ..addCommand(InboxCommand(client))
    ..addCommand(ConversationCommand(client));

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    exit(64);
  } on ApiException catch (e) {
    stderr.writeln('Error: ${e.toString()}');
    exit(1);
  }
}
```

- [ ] **Step 8: Create README.md**

Create `hubsystem-cli/README.md`:

```markdown
# HubSystem CLI

Command-line interface for HubSystem.

## Setup

```bash
export HUBSYSTEM_TOKEN=your-token   # from rails db:seed output
export HUBSYSTEM_URL=http://localhost:3000
```

## Commands

```bash
hubsystem participants                           # list the directory
hubsystem send --to=aria --message="Hello"      # send a message
hubsystem inbox                                 # read your inbox
hubsystem convo --with=aria --subject="Hi"      # start a conversation
hubsystem convo --id=42                         # read a conversation
```

## Build

Requires Dart SDK 3.x:

```bash
dart pub get
dart compile exe bin/hubsystem.dart -o hubsystem
./hubsystem participants
```

## Reusing in Flutter

`lib/api_client.dart` has no CLI dependencies. Import it directly in a Flutter project.
```

- [ ] **Step 9: Commit Dart CLI**

```bash
cd /path/to/hubsystem
git add hubsystem-cli/
git commit -m "feat: dart cli project scaffold (pubspec, api_client, all commands)"
```

---

## Task 6: Push to origin

- [ ] **Step 1: Confirm all specs pass**

```bash
cd hubsystem-server && bin/rspec
```

Expected: all green.

- [ ] **Step 2: Push**

```bash
git push origin main
```

---

## API Decision Notes

1. **`GET /messages/inbox`** — top-level route (not nested under participants) because the caller is the authenticated participant themselves. No participant_id needed; identity comes from the token.

2. **`POST /conversations` dual format** — the new `participant_slugs` format is additive. Old format (`message.to_id`) still works, so existing specs and integrations remain valid.

3. **Slug lookup in messages** — `Participant.find_by(slug: ...) || Participant.find(id)` gives CLI users slug-based addressing while keeping existing ID-based API working.

4. **`from` object in message JSON** — added alongside `from_id` (not replacing it) to avoid breaking existing specs. The inbox and conversation commands use `msg['from']['name']`.

5. **Conversations messages from** — same `message_json` helper update flows into the conversations `messages` action automatically, so `hubsystem convo --id=N` also gets `from.name`.

6. **Dart CLI not compiled** — Dart is written as correct 3.x code but cannot be compiled/tested locally if Dart SDK is not installed. Build instructions in README.
