import 'dart:convert';

import 'package:http_client/console.dart';
import 'package:peon/peon.dart';

abstract class PeonTask with Task {
  final String taskId;
  final Map originalTaskData;

  PeonTask({this.taskId, this.originalTaskData});
}

Future<void> completeTask(PeonTask task) async {
  var client = ConsoleClient();
  try {
    var queue = await getJSQueue(client);
    await queue.sendMessage(
      json.encode({
        'work': 'TaskCompleted',
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
