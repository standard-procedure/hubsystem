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
