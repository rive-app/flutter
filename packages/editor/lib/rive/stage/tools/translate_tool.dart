import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/artboard_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

import 'stage_tool.dart';

class TranslateTool extends StageTool with DraggableTool, TransformingTool {
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

  @override
  List<StageTransformer> get transformers => [ArtboardTranslateTransformer()];

  static final TranslateTool instance = TranslateTool();

  @override
  void endDrag() {
    // Intentionally empty.
  }
}
