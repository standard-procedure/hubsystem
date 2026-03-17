import 'package:args/command_runner.dart';
import '../api_client.dart';

class ConversationCommand extends Command<void> {
  @override final String name = 'convo';
  @override final String description = 'Start or read a conversation';

  final ApiClient client;

  ConversationCommand(this.client) {
    argParser
      ..addOption('with', abbr: 'w', help: 'Participant slug to start conversation with')
      ..addOption('subject', abbr: 's', help: 'Conversation subject (default: "Conversation")')
      ..addOption('message', abbr: 'm', help: 'Opening message (default: "Hello")')
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
