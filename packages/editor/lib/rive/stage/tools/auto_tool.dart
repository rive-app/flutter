import 'dart:ui';

import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

class AutoTool extends StageTool {
  @override
  void draw(Canvas canvas) {}

  @override
  String get icon => 'tool-auto';

  static final AutoTool instance = AutoTool();
}
