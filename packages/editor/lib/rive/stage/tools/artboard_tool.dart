import 'dart:math';
import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';

import 'stage_tool.dart';

class ArtboardTool extends StageTool with DraggableTool {
  Vec2D _startWorldMouse;
  Artboard _artboard;

  /// The artboard tool operates in stage world space.
  @override
  bool get inArtboardSpace => false;

  @override
  void startDrag(Iterable<StageItem> selection, Artboard activeArtboard,
      Vec2D worldMouse) {
    super.startDrag(selection, activeArtboard, worldMouse);
    // Create an artboard and place it at the world location.
    _startWorldMouse = Vec2D.clone(worldMouse);
    _artboard = Artboard()
      ..name = 'New Artboard'
      ..x = worldMouse[0]
      ..y = worldMouse[1]
      ..width = 1
      ..height = 1;
    stage.riveFile.add(_artboard);
  }

  @override
  void endDrag() {
    stage.riveFile.captureJournalEntry();
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    _artboard.x = min(_startWorldMouse[0], worldMouse[0]);
    _artboard.y = min(_startWorldMouse[1], worldMouse[1]);
    _artboard.width = (_startWorldMouse[0] - worldMouse[0]).abs();
    _artboard.height = (_startWorldMouse[1] - worldMouse[1]).abs();
  }

  @override
  void paint(Canvas canvas) {}

  @override
  String get icon => 'tool-artboard';

  static final ArtboardTool instance = ArtboardTool();
}
