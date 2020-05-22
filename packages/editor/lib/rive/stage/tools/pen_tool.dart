import 'dart:ui';

import 'package:bezier/bezier.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:meta/meta.dart';

@immutable
class PenToolInsertTarget {
  final Vec2D worldTranslation;
  final Vec2D translation;
  final PathVertex from;
  final PathVertex to;
  final PointsPath path;

  /// When the insert target needs to split a cubic, this will be non-null.
  final CubicBezier cubic;
  final double cubicSplitT;

  const PenToolInsertTarget({
    this.path,
    this.translation,
    this.worldTranslation,
    this.from,
    this.to,
    this.cubic,
    this.cubicSplitT,
  });

  PenToolInsertTarget copyWith({
    PointsPath path,
    Vec2D translation,
    Vec2D worldTranslation,
    PathVertex from,
    PathVertex to,
    CubicBezier cubic,
    double cubicSplitT,
  }) =>
      PenToolInsertTarget(
        path: path ?? this.path,
        translation: translation ?? this.translation,
        worldTranslation: worldTranslation ?? this.worldTranslation,
        from: from ?? this.from,
        to: to ?? this.to,
        cubic: cubic ?? this.cubic,
        cubicSplitT: cubicSplitT ?? this.cubicSplitT,
      );
}

abstract class PenTool<T extends Component> extends StageTool {
  @override
  bool get activateSendsMouseMove => true;

  PenToolInsertTarget _insertTarget;
  PenToolInsertTarget get insertTarget => _insertTarget;
  PenToolInsertTarget computeInsertTarget(Vec2D worldMouse);

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
      _insertTarget = null;
      return false;
    }
    _insertTarget = computeInsertTarget(worldMouse);
    _showGhostPoint(_insertTarget?.worldTranslation ?? worldMouse);
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
