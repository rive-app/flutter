import 'dart:async';
import 'dart:convert';

import 'package:peon/peon.dart';
import 'package:peon/src/helpers/s3.dart';
import 'package:peon_process/src/helpers/flare_to_rive.dart';

import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';

import 'package:utilities/deserialize.dart';

class FlareToRiveTask with Task {
  final String taskId;
  final String sourceLocation;
  final String targetLocation;
  final String relativeUrl;
  // should switch to connection id I guess?
  final int notifyUserId;
  final Map originalTaskData;

  FlareToRiveTask(
      {this.taskId,
      this.sourceLocation,
      this.targetLocation,
      this.notifyUserId,
      this.relativeUrl,
      this.originalTaskData});

  static FlareToRiveTask fromData(Map<String, dynamic> data) {
    if (!data.containsKey('params')) {
      throw IllegalTask(
          'Expecting a JSON structure with `params` but got $data');
    }

    var params = data.getMap<String, Object>('params');

    return FlareToRiveTask(
        taskId: params.getString('taskId'),
        sourceLocation: params.getString('sourceLocation'),
        targetLocation: params.getString('targetLocation'),
        relativeUrl: params.getString('relativeUrl'),
        notifyUserId: params.getInt('notifyUserId'),
        originalTaskData: data);
  }

  @override
  Future<bool> execute() async {
    var data = await getS3Key(sourceLocation);

    final converter = FlareToRive(taskId)..toFile(String.fromCharCodes(data));

    var exporter = RuntimeExporter(
        core: converter.riveFile,
        info: RuntimeHeader(ownerId: notifyUserId, fileId: 1));

    var bytes = exporter.export();

    await putS3Key(targetLocation, bytes);

    var queue = await getJSQueue();
    await queue.sendMessage(
      json.encode({
        'work': 'TaskCompleted',
        'taskId': taskId,
        'payload': originalTaskData
      }),
      region: defaultRegion,
      service: 'sqs',
    );

    return true;
  }
}
