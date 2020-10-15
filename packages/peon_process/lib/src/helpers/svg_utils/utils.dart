import 'dart:math';
import 'dart:ui';

import 'package:rive_core/rive_file.dart';
import 'package:peon_process/src/helpers/svg_utils/paths.dart';
import 'package:xml/xml_events.dart' hide parseEvents;

String attrOrDefault(List<XmlEventAttribute> attributes, String attributeName,
    String defaultValue) {
  var match = attributes.firstWhere(
      (XmlEventAttribute attribute) => attribute.name == attributeName,
      orElse: () => null);
  return match?.value ?? defaultValue;
}

Offset getShapeOffset(RiveFile file, RivePath rivePath) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = 0.0;
  var maxY = 0.0;
  for (var i = 0; i < rivePath.instructions.length; i++) {
    dynamic instruction = rivePath.instructions[i];
    switch (instruction[0] as pathFuncs) {
      case pathFuncs.addOval:
        var rect = instruction[1] as Rect;
        minX = min(minX, rect.left);
        minY = min(minY, rect.top);
        maxX = max(maxX, rect.left + rect.width);
        maxY = max(maxY, rect.top + rect.height);
        break;
      case pathFuncs.lineTo:
        minX = min(minX, instruction[1] as double);
        minY = min(minY, instruction[2] as double);
        maxX = max(maxX, instruction[1] as double);
        maxY = max(maxY, instruction[2] as double);
        break;
      case pathFuncs.moveTo:
        minX = min(minX, instruction[1] as double);
        minY = min(minY, instruction[2] as double);
        maxX = max(maxX, instruction[1] as double);
        maxY = max(maxY, instruction[2] as double);
        break;
      case pathFuncs.cubicTo:
        minX = min(minX, instruction[1] as double);
        minY = min(minY, instruction[2] as double);
        minX = min(minX, instruction[3] as double);
        minY = min(minY, instruction[4] as double);
        minX = min(minX, instruction[5] as double);
        minY = min(minY, instruction[6] as double);
        maxX = max(maxX, instruction[1] as double);
        maxY = max(maxY, instruction[2] as double);
        maxX = max(maxX, instruction[3] as double);
        maxY = max(maxY, instruction[4] as double);
        maxX = max(maxX, instruction[5] as double);
        maxY = max(maxY, instruction[6] as double);
        break;
      case pathFuncs.addRect:
        var rect = instruction[1] as Rect;
        minX = min(minX, rect.left);
        minY = min(minY, rect.top);
        maxX = max(maxX, rect.left + rect.width);
        maxY = max(maxY, rect.top + rect.height);
        break;
      case pathFuncs.addRRect:
        var rect = instruction[1] as RRect;
        minX = min(minX, rect.left);
        minY = min(minY, rect.top);
        maxX = max(maxX, rect.left + rect.width);
        maxY = max(maxY, rect.top + rect.height);
        break;
      case pathFuncs.transform:
        // DO NOT apply transforms to these paths
        // these transforms get applied to the shapes
        break;
      default:
        break;
    }
  }
  return Offset((minX + maxX) / 2, (minY + maxY) / 2);
}
