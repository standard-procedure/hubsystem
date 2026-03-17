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
