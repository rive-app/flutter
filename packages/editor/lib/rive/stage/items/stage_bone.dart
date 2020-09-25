import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/segment2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/items/stage_joint.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable_component.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_hideable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/bone_tool.dart';

class StageBone extends HideableStageItem<Bone>
    with BoundsDelegate, StageTransformableComponent<Bone> {
  static const double hitDistance = 4;
  static const double hitDistanceSquared = hitDistance * hitDistance;

  @override
  ValueNotifier<bool> get isShownNotifier => stage.showNodesNotifier;
  
  final Path path = Path();
  bool _needsUpdate = true;
  double _worldLength = 0;
  double _screenLength = 0;
  double _angle = 0;
  double _tMin = 0, _tMax = 1;

  Paint _customStroke;

  Color get highlightColor => _customStroke?.color;
  set highlightColor(Color color) {
    if (color == null) {
      _customStroke = null;
    } else {
      _customStroke ??= Paint()
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..color = color;
    }
    stage?.markNeedsRedraw();
  }

  // Store computed segment for the bone (start->end).
  Segment2D _segment;

  // Root bones also manage a base/root joint.
  StageRootJoint _rootJoint;

  // Every stage bone manages the joint at its tip.
  StageJoint _tipJoint;
  StageJoint get tipJoint => _tipJoint;

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 2, inWorldSpace: false)];

  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);

    _tipJoint = StageJoint();
    _tipJoint.initialize(component);
    stage.addItem(_tipJoint);

    if (component is RootBone) {
      _rootJoint = StageRootJoint();
      _rootJoint.initialize(component);
      stage.addItem(_rootJoint);
    }
    boundsChanged();
  }

  @override
  void removedFromStage(Stage stage) {
    stage.removeItem(_tipJoint);
    _tipJoint = null;
    if (_rootJoint != null) {
      stage.removeItem(_rootJoint);
      _rootJoint = null;
    }
    super.removedFromStage(stage);
  }

  @override
  void boundsChanged() {
    final artboard = component.artboard;
    if (artboard == null || stage == null) {
      // Bounds changed for bones gets called during initialization.
      return;
    }
    // Compute aabb
    var start = artboard.renderTranslation(component.worldTranslation);
    var end = artboard.renderTranslation(component.tipWorldTranslation);
    var diff = Vec2D.subtract(Vec2D(), end, start);
    _angle = atan2(diff[1], diff[0]);
    _worldLength = Vec2D.length(diff);
    if (_worldLength != 0) {
      // normalize with computed length
      Vec2D.scale(diff, diff, 1.0 / _worldLength);
    }

    // max bone radius when fully zoomed out in world space
    var maxBoneRadius = BoneRenderer.radius;
    var radiusVector = Vec2D.scale(Vec2D(), diff, maxBoneRadius);
    radiusVector = Vec2D.fromValues(-radiusVector[1], radiusVector[0]);

    var boundingPoints = [
      Vec2D.add(Vec2D(), start, radiusVector),
      Vec2D.subtract(Vec2D(), start, radiusVector),
      Vec2D.add(Vec2D(), end, radiusVector),
      Vec2D.subtract(Vec2D(), end, radiusVector),
    ];
    aabb = AABB.fromPoints(boundingPoints);

    obb = OBB(
      bounds: AABB.fromValues(0, hitDistance, component.length, -hitDistance),
      transform: artboard.transform(component.worldTransform),
    );

    _segment = Segment2D(start, end);
    _needsUpdate = true;

    _rootJoint?.worldTranslation = start;
    _tipJoint.worldTranslation = end;
  }

  /// Do a high fidelity hover hit check against the actual path geometry.
  @override
  bool hitHiFi(Vec2D worldMouse) {
    if (_segment == null) {
      return false;
    }

    var result = _segment.projectPoint(worldMouse);
    if (result.t < _tMin || result.t > _tMax) {
      return false;
    }

    return Vec2D.squaredDistance(result.point, worldMouse) <
        hitDistanceSquared / stage.viewZoom;
  }

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    var screenLength = stage.viewZoom * _worldLength;
    if (_needsUpdate || screenLength != _screenLength) {
      _screenLength = screenLength;
      _tMin = BoneRenderer.radius / _screenLength;
      _tMax = 1 - _tMin;
      _needsUpdate = false;

      BoneRenderer.updatePath(path, screenLength,
          scale: min(1, stage.viewZoom));
    }

    var screen = Vec2D.transformMat2D(
        Vec2D(),
        component.artboard.renderTranslation(component.worldTranslation),
        stage.viewTransform);

    canvas.save();
    canvas.translate(screen[0], screen[1]);
    canvas.rotate(_angle);
    BoneRenderer.draw(
      canvas,
      selectionState.value,
      path,
      customStroke: _customStroke,
    );
    canvas.restore();
    // drawBounds(canvas, pass);
  }
}
