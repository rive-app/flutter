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
    try {
      success = await peonExecute();
    } finally {
      // make sure we update our task if we're completed here...
      await completeTask(this, success);
    }
    return success;
  }
}

Future<void> completeTask(PeonTask task, bool success) async {
  var client = ConsoleClient();
  try {
    var queue = await getJSQueue(client);
    var work = success ? 'TaskCompleted' : 'TaskFailed';
    await queue.sendMessage(
      json.encode({
        'work': work,
        'taskId': task.taskId,
        'payload': task.originalTaskData
      }),
      region: defaultRegion,
      service: 'sqs',
    );
  } finally {
    await client.close(force: true);
  }
}
