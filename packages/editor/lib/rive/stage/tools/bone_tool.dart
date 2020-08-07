import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/math/circle_constant.dart';
import 'package:rive_core/math/mat2d.dart';
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
  static Paint hoveredFill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xCCFFFFFF);
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
      case SelectionState.hovered:
        renderStroke = stroke;
        renderFill = hoveredFill;
        break;
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
  static const double endRadius = 1;

  static Paint fill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x80FFFFFF);
  static Paint hoveredFill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xCCFFFFFF);
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

  static void updatePath(Path path, double length, {double scale = 1}) {
    path.reset();

    var renderRadius = scale * radius;
    var renderEndRadius = scale * endRadius;

    double padding = radius;
    double renderLength = length - padding;
    if (renderLength <= renderRadius + padding) {
      // Do we want to just draw a line here? Figure out what to do... for now
      // don't draw the bone portion.
      return;
    }
    path.moveTo(padding, 0);
    path.cubicTo(
        // Out
        padding,
        -renderRadius * circleConstant,
        // In
        padding + renderRadius * (1 - circleConstant),
        -renderRadius,
        // Pos
        padding + renderRadius,
        -renderRadius);

    path.lineTo(renderLength, -renderEndRadius);
    path.lineTo(renderLength, renderEndRadius);
    path.lineTo(padding + renderRadius, renderRadius);

    path.cubicTo(
        // Out
        padding + renderRadius * (1 - circleConstant),
        // In
        renderRadius,
        padding,
        // Pos
        renderRadius * circleConstant,
        padding,
        0);

    path.close();
  }

  static void draw(Canvas canvas, SelectionState state, Path path) {
    Paint renderStroke, renderFill;
    switch (state) {
      case SelectionState.hovered:
        renderStroke = stroke;
        renderFill = hoveredFill;
        break;
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
    _parentBone = null;
    stage.markNeedsRedraw();
  }

  // Vec2D _ghostPointWorld;
  Vec2D _ghostPointScreen;

  Vec2D _firstJointWorld;

  Bone _parentBone;

  void _showGhostPoint(Vec2D world) {
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
        Vec2D diff;
        Bone bone;
        if (_parentBone != null) {
          bone = Bone();
          var iworld = Mat2D();
          if (!Mat2D.invert(iworld, _parentBone.worldTransform)) {
            // Inversion failed. 0 scale? for now fallback to world, but we may
            // want to show some error here.
            Mat2D.identity(iworld);
          }
          // in this case diff is just the world mouse in local as 0,0 is the
          // previous joint.
          diff = Vec2D.subtract(
              Vec2D(),
              Vec2D.transformMat2D(Vec2D(), worldMouse, iworld),
              Vec2D.fromValues(_parentBone.length, 0));
        } else {
          bone = RootBone()
            ..x = _firstJointWorld[0]
            ..y = _firstJointWorld[1];
          diff = Vec2D.subtract(Vec2D(), worldMouse, _firstJointWorld);
        }

        bone
          ..length = Vec2D.length(diff)
          ..rotation = atan2(diff[1], diff[0]);
        file.addObject(bone);
        if (_parentBone != null) {
          _parentBone.appendChild(bone);
        } else {
          activeArtboard.appendChild(bone);
        }
        _parentBone = bone;
      });
      file.captureJournalEntry();
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
      BoneRenderer.updatePath(path, length, scale: min(1, stage.viewZoom));
      BoneRenderer.draw(canvas, SelectionState.selected, path);
      canvas.restore();
    }
  }
}
