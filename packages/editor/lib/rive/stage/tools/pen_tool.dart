import 'dart:ui';

import 'package:bezier/bezier.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:meta/meta.dart';

enum LockDirection {
  x, // horizontal
  y, // vertical
  pos45, // positive 45 slope
  neg45, // negative 45 slope
}

/// Describes an axis lock with the axis reference point/origin and the aix that should be locked to
@immutable
class LockAxis {
  final Vec2D origin;
  final LockDirection direction;
  const LockAxis(this.origin, this.direction);

  /// Translate a point to the axis
  Vec2D translateToAxis(Vec2D point) {
    switch (direction) {
      case LockDirection.x:
        return Vec2D.fromValues(point[0], origin[1]);
      case LockDirection.y:
        return Vec2D.fromValues(origin[0], point[1]);
      case LockDirection.pos45:
      case LockDirection.neg45:
        final xDiff = point[0] - origin[0];
        final yDiff = point[1] - origin[1];
        final xSign = xDiff >= 0 ? 1 : -1;
        final ySign = yDiff >= 0 ? 1 : -1;
        final dist = (xDiff.abs() + yDiff.abs()) / 2;
        return Vec2D.fromValues(
          origin[0] + (dist * xSign),
          origin[1] + (dist * ySign),
        );
    }
    return point;
  }

  @override
  String toString() => '<Origin: $origin, axis: ${direction.toString()}';

  @override
  bool operator ==(Object o) =>
      o is LockAxis && o.direction == direction && o.origin == origin;

  /// Simple formula to calculate reasonably unique hashes:
  /// h = (a * P1 + b) * P2 + c
  @override
  int get hashCode =>
      (direction.index * 32 + origin[0].round()) * 113 + origin[1].round();
}

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
  Iterable<PackedIcon> get cursorName => PackedIcon.cursorPen;

  @override
  Alignment get cursorAlignment => Alignment.topLeft;

  // Draw after most stage content, but before vertices.
  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(draw, order: 2, inWorldSpace: false),
      ];

  @override
  bool get activateSendsMouseMove => true;

  PenToolInsertTarget _insertTarget;
  PenToolInsertTarget get insertTarget => _insertTarget;
  PenToolInsertTarget computeInsertTarget(Vec2D worldMouse);

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
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

  // Details for locking to an axis if required by the user
  LockAxis _lockAxis;
  LockAxis get lockAxis => _lockAxis;
  set lockAxis(LockAxis value) {
    if (_lockAxis != value) {
      _lockAxis = value;
    }
  }

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
    super.mouseExit(activeArtboard, worldMouse);
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
    var ghostPoint = worldMouse;

    // Should lock to an axis?
    if (ShortcutAction.symmetricDraw.value &&
        lockAxis != null &&
        _insertTarget == null) {
      ghostPoint = lockAxis.translateToAxis(worldMouse);
    }

    _showGhostPoint(_insertTarget?.worldTranslation ?? ghostPoint);
    return true;
  }

  @override
  void deactivate() {
    // Redraw without our vertex.
    _hideGhostPoint();
    super.deactivate();
  }

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolPen;
}
