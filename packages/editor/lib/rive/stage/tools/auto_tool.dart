import 'dart:ui';

import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

class AutoTool extends StageTool {
  @override
  void draw(Canvas canvas) {}

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolAuto;

  static final AutoTool instance = AutoTool();
}
