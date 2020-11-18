import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:archive/archive.dart';
import 'package:peon/peon.dart';
import 'package:peon/src/helpers/s3.dart';
import 'package:peon_process/src/helpers/flare_to_rive.dart';
import 'package:peon_process/src/helpers/task_utils.dart';

import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';

import 'package:utilities/deserialize.dart';

class FlareToRiveTask extends PeonTask {
  final String sourceLocation;
  final String targetLocation;
  final String relativeUrl;
  // should switch to connection id I guess?
  final int notifyUserId;

  FlareToRiveTask(
      {String taskId,
      Map originalTaskData,
      this.sourceLocation,
      this.targetLocation,
      this.notifyUserId,
      this.relativeUrl})
      : super(taskId: taskId, originalTaskData: originalTaskData);

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
  Future<bool> peonExecute() async {
    final data = await getS3Key(sourceLocation);
    final bytes = generateRive(data);
    await putS3Key(targetLocation, bytes);

    return true;
  }

  @visibleForTesting
  Uint8List generateRive(Uint8List flr2dBytes) {
    final archive = ZipDecoder().decodeBytes(flr2dBytes);

    if (archive.isEmpty) {
      return null;
    }

    final flrBytes = archive.first.content as List<int>;
    String revisionString = String.fromCharCodes(flrBytes);

    final converter = FlareToRive(taskId)..toFile(revisionString);

    var exporter = RuntimeExporter(
      core: converter.riveFile,
      info: RuntimeHeader(
        ownerId: notifyUserId,
        fileId: 1,
        version: riveVersion,
      ),
    );

    var bytes = exporter.export();
    return bytes;
  }
}
