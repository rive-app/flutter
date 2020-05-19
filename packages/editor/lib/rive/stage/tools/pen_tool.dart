import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

abstract class PenTool<T extends Component> extends StageTool {
  @override
  bool get activateSendsMouseMove => true;

  @override
  void draw(Canvas canvas) {
    if (_ghostPointScreen == null) {
      return;
    }
    _paintVertex(canvas, Offset(_ghostPointScreen[0], _ghostPointScreen[1]));
  }

  void _paintVertex(Canvas canvas, Offset offset) {
    // Draw twice: once for the background stroke, and a second time for
    // the foreground
    canvas.drawCircle(offset, 4.5, Paint()..color = const Color(0x19000000));
    canvas.drawCircle(offset, 3.5, Paint()..color = const Color(0xFFFFFFFF));
  }

  Vec2D _ghostPointWorld;
  Vec2D _ghostPointScreen;

  Vec2D get ghostPointWorld => _ghostPointWorld;

  void _showGhostPoint(Vec2D world) {
    _ghostPointWorld = Vec2D.clone(world);
    _ghostPointScreen = Vec2D.transformMat2D(Vec2D(),
        stageWorldSpace(stage.activeArtboard, world), stage.viewTransform);
    stage.markNeedsRedraw();
  }

  bool get isShowingGhostPoint => _ghostPointScreen != null;

  void _hideGhostPoint() {
    if (_ghostPointWorld != null) {
      _ghostPointWorld = null;
      _ghostPointScreen = null;
      stage.markNeedsRedraw();
    }
  }

  @override
  void mouseExit(Artboard activeArtboard, Vec2D worldMouse) {
    _hideGhostPoint();
  }

  @override
  bool mouseMove(Artboard activeArtboard, Vec2D worldMouse) {
    if (stage.hoverItem != null || stage.isPanning) {
      _hideGhostPoint();
      // TODO: mark insert target null
      return false;
    }
    // TODO: find an insert target.
    _showGhostPoint(worldMouse);
    return true;
  }

  @override
  void deactivate() {
    // Redraw without our vertex.
    _hideGhostPoint();
    super.deactivate();
  }

  // Draw after most stage content, but before vertices.
  @override
  int get drawOrder => 2;

  @override
  String get icon => 'tool-pen';
}
