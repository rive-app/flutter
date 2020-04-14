import 'package:meta/meta.dart';
import 'package:rive_core/math/vec2d.dart';

mixin MoveableTool {
  Vec2D _mousePosition;

  Vec2D get mousePosition => _mousePosition;
  set mousePosition(Vec2D pos) {
    if (pos != _mousePosition) {
      _mousePosition = pos;
    }
  }

  /// Returns true if the stage should advance after movement.
  @mustCallSuper
  bool updateMove(Vec2D worldMouse) {
    _mousePosition = worldMouse;
    return true;
  }

  void onExit() {
    _mousePosition = null;
  }
}
