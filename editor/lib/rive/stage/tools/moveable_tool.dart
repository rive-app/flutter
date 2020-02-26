import 'package:rive_core/math/vec2d.dart';

mixin MoveableTool {
  Vec2D _mousePosition;

  Vec2D get mousePosition => _mousePosition;
  set mousePosition(Vec2D pos) {
    if (pos != _mousePosition) {
      _mousePosition = pos;
    }
  }

  void updateMove(Vec2D worldMouse) {
    _mousePosition = worldMouse;
  }
  void onExit() {
    _mousePosition = null;
  }
}