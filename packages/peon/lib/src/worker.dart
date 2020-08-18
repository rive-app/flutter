import 'dart:convert';
import 'package:aws_client/sqs.dart';
import 'package:logging/logging.dart';
import 'package:peon/src/tasks/base.dart';

final _log = Logger('peon');

Future<void> loop(Future<SqsQueue> Function() getQueue,
    Map<String, Task Function(Map<String, dynamic>)> tasks) async {
  _log.info('Ready to work.');
  SqsQueue queue;
  while (true) {
    try {
      _log.info('What you want?');
      queue = await getQueue();
      List<SqsMessage> messages =
          await queue.receiveMessage(2, waitSeconds: 10);
      messages.forEach((message) async {
        try {
          bool success = await execute(message, tasks);
          if (success) {
            await queue.deleteMessage(message.receiptHandle);
            _log.info('Work done.');
          } else {
            await queue.deleteMessage(message.receiptHandle);
            _log.info('Work failed, removing from queue.');
          }
          // ignore: avoid_catches_without_on_clauses
        } catch (e, stacktrace) {
          _log.severe('Encountered Error: $e\n'
              'MESSAGE\n$message\n'
              'STACKTRACE:\n$stacktrace');
        }
      });
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stacktrace) {
      _log.severe('Encountered Error: $e\n'
          'STACKTRACE:\n$stacktrace');
    }
  }
}

Future<bool> execute(SqsMessage message,
    Map<String, Task Function(Map<String, dynamic>)> tasks) async {
  _log.info('Work, work: ${message.body}');
  Map<String, dynamic> data;
  try {
    data = json.decode(message.body) as Map<String, dynamic>;
  } on FormatException catch (_) {
    _log.severe('Whaaat? JSON Error, message: ${message.body}');
    return false;
  }
  if (data.containsKey('action')) {
    final task = tasks[data['action']](data);
    return task.execute();
  } else {
    _log.severe('Illegal task ${message.body}, must contain key "action"');
    return false;
  }
}
