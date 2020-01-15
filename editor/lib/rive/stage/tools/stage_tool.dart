import 'package:flutter/foundation.dart';
import 'package:rive_core/math/vec2d.dart';

import '../stage.dart';
import '../stage_item.dart';

abstract class StageTool {
  Stage _stage;
  Stage get stage => _stage;

  /// Override this to check if this tool is valid.
  bool activate(Stage stage) {
    _stage = stage;
    return true;
  }

  Vec2D _lastWorldMouse = Vec2D();
  Vec2D _worldMouseMove = Vec2D();
  Vec2D get lastWorldMouse => _lastWorldMouse;
  Vec2D get worldMouseMove => _worldMouseMove;

  Iterable<StageItem> _selection;
  Iterable<StageItem> get selection => _selection;

  void startDrag(Iterable<StageItem> selection, Vec2D worldMouse) {
    _selection = selection;
    _lastWorldMouse = worldMouse;
  }

  void updateDrag(Vec2D worldMouse);

  @nonVirtual
  void drag(Vec2D worldMouse) {
    _worldMouseMove = Vec2D.subtract(Vec2D(), worldMouse, _lastWorldMouse);
    updateDrag(worldMouse);
    _lastWorldMouse = worldMouse;
  }

  void endDrag();
}
