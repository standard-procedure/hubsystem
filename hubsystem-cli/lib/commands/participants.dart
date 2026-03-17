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
