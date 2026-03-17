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
