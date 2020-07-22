import 'dart:async';

import 'package:peon/peon.dart';
import 'package:peon/src/helpers/s3.dart';
import 'package:peon_process/src/helpers/convert_svg.dart';

import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
// :psyduck:
import 'package:xml/xml_events.dart' as xml show parseEvents;
import 'package:flutter_svg/src/svg/parser_state.dart';
import 'package:utilities/deserialize.dart';

class SvgToRiveTask with Task {
  final String sourceLocation;
  final String targetLocation;
  // should switch to connection id I guess?
  final int notifyUserId;

  SvgToRiveTask({this.sourceLocation, this.targetLocation, this.notifyUserId});

  static SvgToRiveTask fromData(Map<String, dynamic> data) {
    if (!data.containsKey("params")) {
      throw IllegalTask(
          "Expecting a JSON structure with `params` but got $data");
    }

    var params = data.getMap<String, Object>('params');

    return SvgToRiveTask(
        sourceLocation: params.getString('sourceLocation'),
        targetLocation: params.getString('targetLocation'),
        notifyUserId: params.getInt('notifyUserId'));
  }

  @override
  Future<bool> execute() async {
    print(sourceLocation);
    print(targetLocation);
    print(notifyUserId);

    var data = await getS3Key(sourceLocation);

    var drawable =
        await SvgParserStateRived(xml.parseEvents(data), 'bob', svgPathFuncs)
            .parse();
    RiveFile _riveFile = createFromSvg(drawable);

    var exporter = RuntimeExporter(
        core: _riveFile, info: RuntimeHeader(ownerId: notifyUserId, fileId: 1));
    var uint8data = exporter.export();

    await putS3Key(targetLocation, uint8data);
    return true;
  }
}
