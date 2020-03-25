import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';

import 'stage_tool.dart';

class TranslateTool extends StageTool with DraggableTool {
  @override
  void endDrag() {
    stage.riveFile.captureJournalEntry();
  }

  // We want transforms in stage world space (not artboard space). This may
  // change later when we introduce transformers.
  @override
  bool get inArtboardSpace => false;

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
  void draw(Canvas canvas) {}

  @override
  String get icon => 'tool-translate';

  static final TranslateTool instance = TranslateTool();
}
