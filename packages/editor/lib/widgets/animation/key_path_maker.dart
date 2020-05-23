import 'dart:ui';

import 'package:rive_editor/widgets/theme.dart';

void makeFillKeyPath(Path keyPath, RiveThemeData theme, Offset offset) {
  var lower = theme.dimensions.keyLower-0.5;
  var upper = theme.dimensions.keyUpper+0.5;
  keyPath.reset();
  keyPath.moveTo(offset.dx + lower, offset.dy + 0.5);
  keyPath.lineTo(offset.dx + 0.5, offset.dy + lower);
  keyPath.lineTo(offset.dx + upper, offset.dy + 0.5);
  keyPath.lineTo(offset.dx + 0.5, offset.dy + upper);
  keyPath.close();
}

void makeStrokeKeyPath(Path keyPath, RiveThemeData theme, Offset offset) {
  var lower = theme.dimensions.keyLower;
  var upper = theme.dimensions.keyUpper;
  keyPath.reset();
  keyPath.moveTo(offset.dx + lower, offset.dy + 0.5);
  keyPath.lineTo(offset.dx + 0.5, offset.dy + lower);
  keyPath.lineTo(offset.dx + upper, offset.dy + 0.5);
  keyPath.lineTo(offset.dx + 0.5, offset.dy + upper);
  keyPath.close();
}

void makeFillHoldKeyPath(Path keyPath, RiveThemeData theme, Offset offset) {
  var lower = theme.dimensions.keyLower-0.5+1;
  var upper = theme.dimensions.keyUpper+0.5-1;
  keyPath.reset();
  keyPath.moveTo(offset.dx + lower, offset.dy + lower);
  keyPath.lineTo(offset.dx + upper, offset.dy + lower);
  keyPath.lineTo(offset.dx + upper, offset.dy + upper);
  keyPath.lineTo(offset.dx + lower, offset.dy + upper);
  keyPath.close();
}

void makeStrokeHoldKeyPath(Path keyPath, RiveThemeData theme, Offset offset) {
  var lower = theme.dimensions.keyLower+1;
  var upper = theme.dimensions.keyUpper-1;
  keyPath.reset();
  keyPath.moveTo(offset.dx + lower, offset.dy + lower);
  keyPath.lineTo(offset.dx + upper, offset.dy + lower);
  keyPath.lineTo(offset.dx + upper, offset.dy + upper);
  keyPath.lineTo(offset.dx + lower, offset.dy + upper);
  keyPath.close();
}
