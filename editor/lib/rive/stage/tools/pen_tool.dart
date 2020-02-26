import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/user_path.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/moveable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

class PenTool extends StageTool
    with MoveableTool, ClickableTool, DraggableTool {
  static final PenTool instance = PenTool._();

  PenTool._();

  Shape _shape;

  @override
  String get icon => 'tool-pen';

  @override
  void endDrag() {
    // TODO: implement mirrored vertex here.
  }

  @override
  bool activate(Stage stage) {
    super.activate(stage);
    return true;
  }

  @override
  void paint(Canvas canvas) {
    if (mousePosition != null) {
      var mp = Vec2D();
      Vec2D.transformMat2D(mp, mousePosition, stage.viewTransform);
      canvas.drawCircle(
          Offset(mp[0], mp[1]), 5, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    // TODO: implement mirrored vertex here.
  }

  @override
  void onClick(Vec2D worldMouse) {
    var file = stage.riveFile;
    var artboard = file.artboards.first;

    if (_shape == null) {
      _shape = Shape()
        ..name = 'New Shape'
        ..x = worldMouse[0]
        ..y = worldMouse[1]
        ..rotation = 0
        ..scaleX = 1
        ..scaleY = 1
        ..opacity = 1;

      var path = UserPath()
        ..name = 'Pen Rect'
        ..x = 0
        ..y = 0
        ..rotation = 0
        ..scaleX = 1
        ..scaleY = 1
        ..opacity = 1;

      // TODO: remove hardcoded vertices
      path.addVertex(0, 0);
      path.addVertex(100, 100);
      path.addVertex(100, 200);
      path.addVertex(0, 200);
      path.isClosed = true;

      file.startAdd();
      file.add(_shape);
      file.add(path);

      _shape.appendChild(path);
      artboard.appendChild(_shape);

      file.cleanDirt();
      file.completeAdd();
    }
  }
}
