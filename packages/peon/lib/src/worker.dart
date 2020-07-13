import 'dart:convert';
import 'package:aws_client/sqs.dart';
import 'package:peon/src/task.dart';

Future<void> loop(SqsQueue queue) async {
  print('Ready to work.');
  while (true) {
    print('What you want?');
    List<SqsMessage> messages = await queue.receiveMessage(2, waitSeconds: 10);
    messages.forEach((message) async {
      try {
        bool success = await execute(message);
        if (success) {
          await queue.deleteMessage(message.receiptHandle);
        }
        // ignore: avoid_catches_without_on_clauses
      } catch (e, stacktrace) {
        print('Encountered Error: $e\n'
            'MESSAGE\n$message\n'
            'STACKTRACE:\n$stacktrace');
      }
    });
  }
}

Future<bool> execute(SqsMessage message) async {
  print('Work, work: ${message.body}');
  Map<String, dynamic> data;
  try {
    data = json.decode(message.body) as Map<String, dynamic>;
  } on FormatException catch (_) {
    print('Whaaat? JSON Error, message: ${message.body}');
    return false;
  }

  final task = Task.fromData(data);
  return task.execute();
}
