import 'dart:convert';

import 'package:http_client/console.dart';
import 'package:peon/peon.dart';

abstract class PeonTask with Task {
  final String taskId;
  final Map originalTaskData;

  PeonTask({this.taskId, this.originalTaskData});

  // actual task implementation
  Future<bool> peonExecute();

  @override
  Future<bool> execute() async {
    bool success = false;
    String error;
    try {
      success = await peonExecute();
    } on Exception catch (e) {
      error = e.toString();
      rethrow;
      // ignore: avoid_catching_errors
    } on Error catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      // make sure we update our task if we're completed here...
      await completeTask(this, success, error);
    }
    return success;
  }
}

Future<void> completeTask(PeonTask task, bool success, String message) async {
  var client = ConsoleClient();
  try {
    var queue = await getJSQueue(client);
    var work = success ? 'TaskCompleted' : 'TaskFailed';
    await queue.sendMessage(
      json.encode({
        'work': work,
        'taskId': task.taskId,
        'payload': task.originalTaskData,
        'message': message
      }),
      region: defaultRegion,
      service: 'sqs',
    );
  } finally {
    await client.close(force: true);
  }
}
