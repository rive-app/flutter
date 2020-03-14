import 'package:flutter/foundation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

mixin DraggableTool {
  Iterable<StageItem> _selection;
  Iterable<StageItem> get selection => _selection;

  Vec2D _lastWorldMouse;
  Vec2D get lastWorldMouse => _lastWorldMouse;

  Vec2D _worldMouseMove = Vec2D();
  Vec2D get worldMouseMove => _worldMouseMove;

  /// Start a drag operation in world coordinates relative to the origin of the
  /// [activeArtboard]. The [activeArtboard] for this operation is provided as
  /// well.
  void startDrag(
    Iterable<StageItem> selection,
    Artboard activeArtboard,
    Vec2D worldMouse,
  ) {
    _selection = selection;
    _lastWorldMouse = worldMouse;
  }

  @nonVirtual
  void drag(Vec2D worldMouse) {
    _worldMouseMove = Vec2D.subtract(Vec2D(), worldMouse, _lastWorldMouse);
    updateDrag(worldMouse);
    _lastWorldMouse = worldMouse;
  }

  void updateDrag(Vec2D worldMouse);
  void endDrag();
}
