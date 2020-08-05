import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/math/circle_constant.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:utilities/restorer.dart';

// ignore: avoid_classes_with_only_static_members
class BoneJointRenderer {
  static const double radius = 3.5;
  static Path path = Path()
    ..addOval(const Rect.fromLTRB(
      -radius,
      -radius,
      radius,
      radius,
    ));
  static Paint fill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x80FFFFFF);
  static Paint selectedFill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF008BFF);
  static Paint stroke = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x40000000)
    ..strokeWidth = 2;
  static Paint jointSelectedStroke = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 2;

  static void draw(Canvas canvas, SelectionState state) {
    Paint renderStroke, renderFill;
    switch (state) {
      case SelectionState.selected:
        renderStroke = jointSelectedStroke;
        renderFill = selectedFill;
        break;
      default:
        renderStroke = stroke;
        renderFill = fill;
        break;
    }
    canvas.drawPath(path, renderStroke);
    canvas.drawPath(path, renderFill);
  }
}

class BoneRenderer {
  static const double radius = 7;

  static Paint fill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x80FFFFFF);
  static Paint selectedFill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF008BFF);
  static Paint stroke = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x40000000)
    ..strokeWidth = 2;
  static Paint jointSelectedStroke = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 2;

  static void updatePath(Path path, double length) {
    path.reset();
    double padding = radius;
    double renderLength = length - padding * 2;
    if (renderLength <= radius + padding) {
      // Do we want to just draw a line here? Figure out what to do... for now
      // don't draw the bone portion.
      return;
    }

    path.moveTo(padding, 0);
    path.cubicTo(
        // Out
        padding,
        -radius * circleConstant,
        // In
        padding + radius * (1 - circleConstant),
        -radius,
        // Pos
        padding + radius,
        -radius);

    path.lineTo(renderLength, 0);
    path.lineTo(padding + radius, radius);

    path.cubicTo(
        // Out
        padding + radius * (1 - circleConstant),
        // In
        radius,
        padding,
        // Pos
        radius * circleConstant,
        padding,
        0);

    path.close();
  }

  static void draw(Canvas canvas, SelectionState state, Path path) {
    Paint renderStroke, renderFill;
    switch (state) {
      case SelectionState.selected:
        renderStroke = jointSelectedStroke;
        renderFill = selectedFill;
        break;
      default:
        renderStroke = stroke;
        renderFill = fill;
        break;
    }
    canvas.drawPath(path, renderStroke);
    canvas.drawPath(path, renderFill);
  }
}

class BoneTool extends StageTool {
  static final BoneTool instance = BoneTool();

  // Draw after most stage content, but before vertices.
  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(draw, order: 2, inWorldSpace: false),
      ];

  @override
  Iterable<PackedIcon> get icon => PackedIcon.toolBone;

  @override
  Iterable<PackedIcon> get cursorName => PackedIcon.cursorBone;

  @override
  Alignment get cursorAlignment => Alignment.bottomRight;

  @override
  bool get activateSendsMouseMove => true;

  Restorer _selectionRestorer;

  @override
  bool activate(Stage stage) {
    if (!super.activate(stage)) {
      return false;
    }
    _selectionRestorer = stage.suppressSelection();
    return true;
  }

  @override
  void deactivate() {
    _selectionRestorer?.restore();
    super.deactivate();
    _firstJointWorld = null;
    stage.markNeedsRedraw();
  }

  Vec2D _ghostPointWorld;
  Vec2D _ghostPointScreen;

  Vec2D _firstJointWorld;

  void _showGhostPoint(Vec2D world) {
    _ghostPointWorld = Vec2D.clone(world);
    _ghostPointScreen = Vec2D.transformMat2D(Vec2D(),
        stageWorldSpace(stage.activeArtboard, world), stage.viewTransform);
    stage.markNeedsRedraw();
  }

  @override
  void click(Artboard activeArtboard, Vec2D worldMouse) {
    super.click(activeArtboard, worldMouse);
    if (_firstJointWorld != null) {
      // make the root bone.
      var file = activeArtboard.context;
      file.batchAdd(() {
        // TODO: worldMouse & firstJointWorld need to be in parent space
        // (currently the artboard is the parent, so world space matches
        // artboard space).
        var diff = Vec2D.subtract(Vec2D(), worldMouse, _firstJointWorld);
        var bone = RootBone()
          ..x = _firstJointWorld[0]
          ..y = _firstJointWorld[1]
          ..length = Vec2D.length(diff)
          ..rotation = atan2(diff[1], diff[0]);

        file.addObject(bone);
        activeArtboard.appendChild(bone);
      });
    }
    _firstJointWorld = Vec2D.clone(worldMouse);
    stage.markNeedsRedraw();
  }

  /// Returns true if the stage should advance after movement.
  @override
  bool mouseMove(Artboard activeArtboard, Vec2D worldMouse) {
    _showGhostPoint(worldMouse);
    return true;
  }

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    canvas.save();
    canvas.translate(
        _ghostPointScreen[0].round() + 0.5, _ghostPointScreen[1].round() + 0.5);
    BoneJointRenderer.draw(canvas, SelectionState.none);
    canvas.restore();
    if (_firstJointWorld != null) {
      var firstJointScreen = Vec2D.transformMat2D(
          Vec2D(),
          stageWorldSpace(stage.activeArtboard, _firstJointWorld),
          stage.viewTransform);
      canvas.save();
      canvas.translate(
          firstJointScreen[0].round() + 0.5, firstJointScreen[1].round() + 0.5);
      BoneJointRenderer.draw(canvas, SelectionState.selected);

      var diff = Vec2D.subtract(Vec2D(), _ghostPointScreen, firstJointScreen);
      var angle = atan2(diff[1], diff[0]);
      var length = Vec2D.length(diff);
      var path = Path();
      canvas.rotate(angle);
      BoneRenderer.updatePath(path, length);
      BoneRenderer.draw(canvas, SelectionState.selected, path);
      canvas.restore();
    }
  }
}
