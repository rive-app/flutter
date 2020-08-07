import 'dart:ui';

import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/bone_tool.dart';

class StageJoint extends StageItem<Bone> {
  static const double hitRadius = BoneJointRenderer.radius + 2;
  static const double hitRadiusSquared = hitRadius * hitRadius;
  static const double _maxWorldJointSize =
      BoneJointRenderer.radius / Stage.minZoom;
  Vec2D _worldTranslation;

  set worldTranslation(Vec2D value) {
    _worldTranslation = value;
    aabb = AABB.fromValues(
      _worldTranslation[0] - _maxWorldJointSize,
      _worldTranslation[1] - _maxWorldJointSize,
      _worldTranslation[0] + _maxWorldJointSize,
      _worldTranslation[1] + _maxWorldJointSize,
    );
    stage?.updateBounds(this);
  }

  Vec2D get worldTranslation => _worldTranslation;

  @override
  bool hitHiFi(Vec2D worldMouse) {
    return Vec2D.squaredDistance(worldMouse, _worldTranslation) <=
        hitRadiusSquared / (stage.viewZoom * stage.viewZoom);
  }

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 3, inWorldSpace: false)];

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    var screen =
        Vec2D.transformMat2D(Vec2D(), _worldTranslation, stage.viewTransform);

    canvas.save();
    canvas.translate(screen[0], screen[1]);
    BoneJointRenderer.draw(canvas, selectionState.value);
    canvas.restore();
    drawBounds(canvas, pass);
  }
}
