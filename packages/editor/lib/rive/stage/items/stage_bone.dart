import 'dart:math';
import 'dart:ui';

import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_hideable.dart';
import 'package:rive_editor/rive/stage/tools/bone_tool.dart';
import 'package:rive_editor/selectable_item.dart';

class StageBone extends HideableStageItem<Bone> with BoundsDelegate {
  final Path path = Path();
  bool _needsUpdate = true;
  double _worldLength = 0;
  double _screenLength = 0;
  double _angle = 0;
  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 2, inWorldSpace: false)];

  @override
  void boundsChanged() {
    // Compute aabb
    var start = component.worldTranslation;
    var end = component.tipWorldTranslation;
    var diff = Vec2D.subtract(Vec2D(), end, start);
    _angle = atan2(diff[1], diff[0]);
    _worldLength = Vec2D.length(diff);
    if (_worldLength != 0) {
      // normalize with computed length
      Vec2D.scale(diff, diff, 1.0 / _worldLength);
    }

    // max bone radius when fully zoomed out in world space
    var maxBoneRadius = BoneRenderer.radius / Stage.minZoom;
    var radiusVector = Vec2D.scale(Vec2D(), diff, maxBoneRadius);
    radiusVector = Vec2D.fromValues(-radiusVector[1], radiusVector[0]);

    var boundingPoints = [
      Vec2D.add(Vec2D(), start, radiusVector),
      Vec2D.subtract(Vec2D(), start, radiusVector),
      Vec2D.add(Vec2D(), end, radiusVector),
      Vec2D.subtract(Vec2D(), end, radiusVector),
    ];
    aabb = AABB.fromPoints(boundingPoints);
    _needsUpdate = true;
  }

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    var screenLength = stage.viewZoom * _worldLength;
    if (_needsUpdate || screenLength != _screenLength) {
      _screenLength = screenLength;
      _needsUpdate = false;
      BoneRenderer.updatePath(path, screenLength);
    }

    var screen = Vec2D.transformMat2D(
        Vec2D(),
        component.artboard.renderTranslation(component.worldTranslation),
        stage.viewTransform);

    canvas.save();
    canvas.translate(screen[0], screen[1]);
    canvas.rotate(_angle);
    BoneRenderer.draw(canvas, SelectionState.none, path);
    canvas.restore();
  }
}
