import 'dart:ui';

import 'package:rive_editor/rive/stage/stage.dart';

abstract class StageTool {
  Stage _stage;
  Stage get stage => _stage;

  String get icon;

  /// Override this to check if this tool is valid.
  bool activate(Stage stage) {
    _stage = stage;
    return true;
  }

  void paint(Canvas canvas);
}
