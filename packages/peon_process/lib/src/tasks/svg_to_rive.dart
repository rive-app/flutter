import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:peon/peon.dart';
import 'package:peon/src/helpers/s3.dart';
import 'package:peon_process/src/helpers/convert_svg.dart';
import 'package:peon_process/src/helpers/task_utils.dart';

import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
// :psyduck:
import 'package:xml/xml_events.dart' as xml show parseEvents;
import 'package:flutter_svg/src/svg/parser_state.dart';
import 'package:utilities/deserialize.dart';

final _log = Logger('peon');

class SvgToRiveTask extends PeonTask {
  final String sourceLocation;
  final String targetLocation;
  final String relativeUrl;
  // should switch to connection id I guess?
  final int notifyUserId;

  SvgToRiveTask({
    String taskId,
    Map originalTaskData,
    this.sourceLocation,
    this.targetLocation,
    this.notifyUserId,
    this.relativeUrl,
  }) : super(taskId: taskId, originalTaskData: originalTaskData);

  static SvgToRiveTask fromData(Map<String, dynamic> data) {
    if (!data.containsKey('params')) {
      throw IllegalTask(
          'Expecting a JSON structure with `params` but got $data');
    }

    var params = data.getMap<String, Object>('params');

    return SvgToRiveTask(
        taskId: params.getString('taskId'),
        sourceLocation: params.getString('sourceLocation'),
        targetLocation: params.getString('targetLocation'),
        relativeUrl: params.getString('relativeUrl'),
        notifyUserId: params.getInt('notifyUserId'),
        originalTaskData: data);
  }

  Future<String> clean(String input) async {
    String cleaned = input;
    // if we have svgcleaner install lets run that to clean this file.
    ProcessResult output;
    Directory tempDir;

    try {
      var tmpName = sourceLocation.hashCode.toString();
      var tempDir = await Directory.systemTemp.createTemp();
      var inPath = '${tempDir.path}/$tmpName.in.svg';
      var outPath = '${tempDir.path}/$tmpName.out.svg';
      var inFile = File(inPath);
      await inFile.create();
      await inFile.writeAsString(input);
      output = await Process.run('svgcleaner', [
        '--remove-nonsvg-elements=false',
        '--ungroup-groups=false',
        '--group-by-style=false',
        '--merge-gradients=false',
        '--remove-nonsvg-attributes=false',
        '--remove-unreferenced-ids=false',
        '--trim-ids=false',
        '--indent=4',
        '--allow-bigger-file',
        inPath,
        outPath
      ]);
      if (output.exitCode == 0) {
        var outFile = File(outPath);
        cleaned = await outFile.readAsString();
      } else {
        _log.severe('Problem running svgcleaner for $taskId'
            '\nstdout:\n${output.stdout.toString().split('\n')}'
            '\nstderr:\n${output.stderr.toString().split('\n')}');
      }
    } on ProcessException catch (e, s) {
      _log.severe('Problem running svgcleaner for $taskId', e, s);
    } finally {
      await tempDir?.delete(recursive: true);
    }
    return cleaned;
  }

  @override
  Future<bool> execute() async {
    var data = await getS3Key(sourceLocation);
    var cleanedData = await clean(String.fromCharCodes(data));

    // the key is just there for debugging purposes
    var drawable = await SvgParserStateRived(
            xml.parseEvents(cleanedData), 'rive_key', svgPathFuncs)
        .parse();
    if (drawable == null) {
      throw Exception('Could not parse svg file\n\n'
          'Original:\n$data\n\n'
          'Cleaned:\n$cleanedData\n\n');
    }
    RiveFile _riveFile = createFromSvg(drawable);

    var exporter = RuntimeExporter(
        core: _riveFile, info: RuntimeHeader(ownerId: notifyUserId, fileId: 1));
    var uint8data = exporter.export();

    await putS3Key(targetLocation, uint8data);
    await completeTask(this);
    return true;
  }
}
