import 'dart:math';
import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/constants.dart';
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
    var file = stage.riveFile;
    file.batchAdd(() {
      var solidColor = SolidColor()..colorValue = 0xFF313131;
      var fill = Fill();
      _artboard = Artboard()
        ..name = 'New Artboard'
        ..x = worldMouse[0]
        ..y = worldMouse[1]
        ..originX = 0
        ..originY = 0
        ..width = 1
        ..height = 1;
      file.add(_artboard);
      file.add(fill);
      file.add(solidColor);
      _artboard.appendChild(fill);
      fill.appendChild(solidColor);
    });
  }

  @override
  void endDrag() {
    stage.riveFile.captureJournalEntry();
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    switch (editModeMap[editMode]) {
      case DraggingMode.symmetric:
        final maxChange = max(
          (_startWorldMouse[0] - worldMouse[0]).abs(),
          (_startWorldMouse[1] - worldMouse[1]).abs(),
        );
        var x1 = (_startWorldMouse[0] < worldMouse[0])
            ? _startWorldMouse[0]
            : _startWorldMouse[0] - maxChange;
        var y1 = (_startWorldMouse[1] < worldMouse[1])
            ? _startWorldMouse[1]
            : _startWorldMouse[1] - maxChange;
        _artboard.x = x1;
        _artboard.y = y1;
        _artboard.width = maxChange;
        _artboard.height = maxChange;
        break;
      default:
        _artboard.x = min(_startWorldMouse[0], worldMouse[0]);
        _artboard.y = min(_startWorldMouse[1], worldMouse[1]);
        _artboard.width = (_startWorldMouse[0] - worldMouse[0]).abs();
        _artboard.height = (_startWorldMouse[1] - worldMouse[1]).abs();
    }
  }

  @override
  void draw(Canvas canvas) {}

  @override
  String get icon => 'tool-artboard';

  @override
  void onEditModeChange() {
    // if the edit mode is changed lets just treat it as a fake drag.
    if (lastWorldMouse != null) {
      updateDrag(lastWorldMouse);
    }
  }

  static final ArtboardTool instance = ArtboardTool();
}
