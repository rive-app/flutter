import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

import 'stage_tool.dart';

class TranslateTool extends StageTool {
  @override
  void endDrag() {
    stage.riveFile.captureJournalEntry();
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    for (final stageItem in selection) {
      if (stageItem is StageItem) {
        stageItem.component.x += worldMouseMove[0];
        stageItem.component.y += worldMouseMove[1];
      }
    }
  }

  @override
  void paint(Canvas canvas) {}

  @override
  String get icon => 'tool-translate';

  static final TranslateTool instance = TranslateTool();
}
