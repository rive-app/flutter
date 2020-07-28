import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('Tasks Api');

class TaskResult {
  final String taskId;
  const TaskResult(this.taskId);
  factory TaskResult.fromData(Map<String, dynamic> json) {
    var data = json.getMap<String, dynamic>('data');
    var taskId = data.getString('taskId');
    if (taskId != null) {
      return TaskResult(taskId);
    }
    return null;
  }
}

class TasksApi {
  TasksApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<TaskResult> task(String type, String name, Uint8List body) async {
    var res = await api.post(
      '${api.host}/api/tasks/$type/$name',
      body: body,
    );

    try {
      final data = json.decodeMap(res.body);
      return TaskResult.fromData(data);
    } on FormatException catch (e) {
      _log.severe('Error reading task response: $e');
      rethrow;
    }
  }

  Future<TaskResult> convertSVG(Uint8List svg) async {
    return task('svg', 'convert', svg);
  }

  Future<TaskResult> convertFLR(Uint8List flr) async {
    return task('flare', 'convert', flr);
  }

  Future<Uint8List> taskData(String taskId) async {
    var res = await api.get('${api.host}/api/tasks/$taskId');
    // TODO: log non 200s?
    return res.bodyBytes;
  }
}

//
// https://slimer.rive.app/api/tasks/svg/c2ac4747-9ce6-4b23-bf06-6c22a52b1c9b

// Post to:
// https://slimer.rive.app/api/tasks/svg/convert
// Body (binary)
// select an svg file
// It'll return you a job
// {
//     "type": "success",
//     "message": "OK",
//     "data": {
//         "taskId": "c2ac4747-9ce6-4b23-bf06-6c22a52b1c9b"
//     }
// }
