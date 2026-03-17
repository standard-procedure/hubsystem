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
