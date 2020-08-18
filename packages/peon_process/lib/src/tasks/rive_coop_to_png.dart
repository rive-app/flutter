import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:peon/peon.dart';
import 'package:peon/src/helpers/s3.dart';
import 'package:rive_core/coop_importer.dart';

import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';

import 'package:utilities/deserialize.dart';

final _log = Logger('peon');

class RiveCoopToPng with Task {
  final String taskId;
  final String sourceLocation;
  final String targetLocation;
  // should switch to connection id I guess?
  final int ownerId;
  final int fileId;
  final Map originalTaskData;

  RiveCoopToPng(
      {this.taskId,
      this.sourceLocation,
      this.targetLocation,
      this.ownerId,
      this.fileId,
      this.originalTaskData});

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
        ownerId: params.getInt('ownerId'),
        fileId: params.getInt('fileId'),
        originalTaskData: data);
  }

  Future<Uint8List> convert(Uint8List runtimeBinary) async {
    // if we have svgcleaner install lets run that to clean this file.

    ProcessResult execOutput;
    Directory tempDir;

    try {
      var tmpName = sourceLocation.hashCode.toString();
      var tempDir = await Directory.systemTemp.createTemp();
      var inPath = "${tempDir.path}/$tmpName.in.riv";
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
      } else {
        _log.severe('Thumbnail Generation Failed for ${taskId} '
            '\nstdout:\n${execOutput.stdout.toString().split('\n')}'
            '\nstderr:\n${execOutput.stderr.toString().split('\n')}');
      }
    } finally {
      await tempDir?.delete(recursive: true);
    }

    return null;
  }

  @override
  Future<bool> execute() async {
    // FML
    var data = await getS3Key(sourceLocation, 'us-east-1');
    var riveFile = RiveFile(fileId.toString(), localDataPlatform: null);
    var coopImporter = CoopImporter(core: riveFile);
    coopImporter.import(data);

    var exporter = RuntimeExporter(
        core: riveFile, info: RuntimeHeader(ownerId: ownerId, fileId: fileId));
    var exportedRiveBinary = exporter.export();
    var svgdata = await convert(exportedRiveBinary);
    if (svgdata == null) {
      return false;
    }

    await putS3Key(targetLocation, svgdata, 'us-east-1');

    var queue = await getJSQueue();
    await queue.sendMessage(json.encode({
      'work': 'TaskCompleted',
      'taskId': taskId,
      'payload': originalTaskData
    }));

    return true;
  }
}
