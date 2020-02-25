import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/user_path.dart';
import 'package:rive_editor/rive/stage/tools/moveable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

class PenTool extends StageTool with MoveableTool {
  static final PenTool instance = PenTool._();

  PenTool._();

  Vec2D _mousePosition = Vec2D();

  @override
  String get icon => 'tool-pen';

  Path get path => UserPath()
    ..name = 'Path'
    ..x = 0
    ..y = 0
    ..rotation = 0
    ..scaleX = 1
    ..scaleY = 1;

  Shape shape(Vec2D worldMouse) => Shape()
    ..name = 'New Shape'
    ..x = worldMouse[0]
    ..y = worldMouse[1]
    ..rotation = 0
    ..scaleX = 1
    ..scaleY = 1
    ..opacity = 1;

  @override
  void endDrag() {
    // TODO: implement mirrored vertex here.
  }

  @override
  void paint(Canvas canvas) {
    var mp = Vec2D();
    Vec2D.transformMat2D(mp, _mousePosition, stage.viewTransform);
    canvas.drawCircle(
        Offset(mp[0], mp[1]),
        5,
        Paint()
          ..color = const Color(0xFFFFFFFF));
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    // TODO: implement mirrored vertex here.
  }

  @override
  void updateMove(Vec2D worldMouse) {
    _mousePosition = worldMouse;
  }
}
