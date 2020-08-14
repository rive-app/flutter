import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:logging/logging.dart';
import 'package:peon/peon.dart';
import 'package:peon/src/helpers/s3.dart';
import 'package:rive_core/coop_importer.dart';

import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';

import 'package:utilities/deserialize.dart';

final _log = Logger('peon');

class SourceDetail {
  final String key;
  final String name;
  final String path;
  final int fileId;
  final int ownerId;

  SourceDetail({this.key, this.name, this.path, this.fileId, this.ownerId});
  static SourceDetail fromData(Map<String, Object> data) {
    return SourceDetail(
      key: data.getString('key'),
      name: data.getString('name'),
      path: data.getString('path'),
      fileId: data.getInt('fileId'),
      ownerId: data.getInt('ownerId'),
    );
  }
}

class ExportRive with Task {
  final String taskId;
  final String sourceBase;
  final List<SourceDetail> sourceDetails;
  final String targetLocation;
  final String relativeUrl;
  // should switch to connection id I guess?
  final int notifyUserId;
  final Map originalTaskData;

  ExportRive(
      {this.taskId,
      this.sourceBase,
      this.sourceDetails,
      this.targetLocation,
      this.notifyUserId,
      this.relativeUrl,
      this.originalTaskData});

  static ExportRive fromData(Map<String, Object> data) {
    if (!data.containsKey("params")) {
      throw IllegalTask(
          "Expecting a JSON structure with `params` but got $data");
    }

    var params = data.getMap<String, Object>('params');
    var details = params.getList<Map<String, Object>>('sourceDetails');
    var sourceDetails = details.map(SourceDetail.fromData).toList();

    return ExportRive(
        taskId: params.getString('taskId'),
        sourceBase: params.getString('sourceBase'),
        sourceDetails: sourceDetails,
        targetLocation: params.getString('targetLocation'),
        relativeUrl: params.getString('relativeUrl'),
        notifyUserId: params.getInt('notifyUserId'),
        originalTaskData: data);
  }

  @override
  Future<bool> execute() async {
    Directory tempDir;
    Uint8List zipBytes;
    // TODO: add file id and owner ids to all these files
    try {
      var tempDir = await Directory.systemTemp.createTemp();
      for (var i = 0; i < sourceDetails.length; i++) {
        var sourceLocation = '$sourceBase${sourceDetails[i].key}';
        var data = await getS3Key(sourceLocation, 'us-east-1');

        var riveFile = RiveFile(sourceDetails[i].fileId.toString(),
            localDataPlatform: null);
        var coopImporter = CoopImporter(core: riveFile);
        coopImporter.import(data);
        var exporter = RuntimeExporter(
            core: riveFile,
            info: RuntimeHeader(
              ownerId: sourceDetails[i].ownerId,
              fileId: sourceDetails[i].fileId,
            ));
        var exportedRiveBinary = exporter.export();

        var filePath =
            "${tempDir.path}${sourceDetails[i].path}/${sourceDetails[i].name}.riv";

        var exportedFile = File(filePath);
        await exportedFile.create(recursive: true);
        await exportedFile.writeAsBytes(exportedRiveBinary);
      }
      var encoder = ZipFileEncoder();
      encoder.zipDirectory(tempDir, filename: 'out.zip');
      zipBytes = File('out.zip').readAsBytesSync();
    } finally {
      await tempDir?.delete(recursive: true);
    }

    await putS3Key(targetLocation, zipBytes);

    var queue = await getJSQueue();
    await queue.sendMessage(json.encode({
      "work": "TaskCompleted",
      "taskId": taskId,
      "payload": originalTaskData
    }));

    return true;
  }
}
