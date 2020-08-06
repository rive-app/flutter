import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:peon/peon.dart';
import 'package:peon/src/helpers/s3.dart';
import 'package:rive_core/coop_importer.dart';

import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';

import 'package:utilities/deserialize.dart';

class RiveCoopToPng with Task {
  final String taskId;
  final String sourceLocation;
  final String targetLocation;
  // should switch to connection id I guess?
  final int notifyUserId;

  RiveCoopToPng(
      {this.taskId,
      this.sourceLocation,
      this.targetLocation,
      this.notifyUserId});

  static RiveCoopToPng fromData(Map<String, dynamic> data) {
    if (!data.containsKey("params")) {
      throw IllegalTask(
          "Expecting a JSON structure with `params` but got $data");
    }

    var params = data.getMap<String, Object>('params');

    return RiveCoopToPng(
        taskId: params.getString('taskId'),
        sourceLocation: params.getString('sourceLocation'),
        targetLocation: params.getString('targetLocation'),
        notifyUserId: params.getInt('notifyUserId'));
  }

  Future<Uint8List> convert(Uint8List runtimeBinary) async {
    // if we have svgcleaner install lets run that to clean this file.

    ProcessResult execOutput;
    Directory tempDir;

    try {
      var tmpName = sourceLocation.hashCode.toString();
      var tempDir = await Directory.systemTemp.createTemp();
      var inPath = "${tempDir.path}/$tmpName.in.coop";
      var outPath = "${tempDir.path}/$tmpName.out.png";
      var inFile = File(inPath);
      await inFile.create();
      await inFile.writeAsBytes(runtimeBinary);

      var thumbnail_converter =
          Platform.environment['THUMBNAIL_GENERATOR_PATH'];
      if (thumbnail_converter == null) {
        throw Exception(
            'Env variable THUMBNAIL_GENERATOR_PATH is required for png generation');
      }

      execOutput = await Process.run(
        thumbnail_converter,
        [
          inPath,
          outPath,
        ],
      );
      if (execOutput.exitCode == 0) {
        var outFile = File(outPath);
        return await outFile.readAsBytes();
      }
    } on ProcessException catch (e) {
      print(e);
      print('Problem running command, skipping');
    } finally {
      await tempDir?.delete(recursive: true);
    }

    // should probably just die
    return null;
  }

  @override
  Future<bool> execute() async {
    var data = await getS3Key(sourceLocation);
    var riveFile = RiveFile('0', localDataPlatform: null);
    var coopImporter = CoopImporter(core: riveFile);
    coopImporter.import(data);

    var exporter = RuntimeExporter(
        core: riveFile, info: RuntimeHeader(ownerId: notifyUserId, fileId: 1));
    var exportedRiveBinary = exporter.export();
    var svgdata = await convert(exportedRiveBinary);
    if (svgdata == null) {
      return false;
    }

    await putS3Key(targetLocation, svgdata);
    var queue = await getJSQueue();

    await queue.sendMessage(json.encode({
      "work": "ApiGatewayPushMessage",
      "ownerId": notifyUserId,
      "payload": {
        "action": "TaskCompleted",
        "params": {"taskId": taskId}
      }
    }));

    return true;
  }
}
