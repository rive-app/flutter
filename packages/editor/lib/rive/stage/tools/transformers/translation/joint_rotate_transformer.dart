import 'dart:math';

import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/items/stage_bone.dart';
import 'package:rive_editor/rive/stage/items/stage_joint.dart';
import 'package:rive_editor/rive/stage/items/stage_rotation_handle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/utilities.dart';

class _RotatingBone {
  final Bone bone;
  final double startAngle;

  _RotatingBone(this.bone) : startAngle = bone.rotation;
}

class JointRotateTransformer extends StageTransformer {
  Iterable<_RotatingBone> _bones;
  final StageRotationHandle handle;

  JointRotateTransformer({this.handle}) {
    var transformComponents = TransformComponents();
    Mat2D.decompose(handle.transform, transformComponents);
    _startHandleAngle = transformComponents.rotation;
  }

  double _startHandleAngle = 0;
  double _cursorAngle = 0;
  double _startCursorAngle = 0;

  @override
  void advance(DragTransformDetails details) {
    var toCursor = Vec2D.subtract(
        Vec2D(), details.artboardWorld.current, handle.translation);

    var lastCursorAngle = _cursorAngle;
    _cursorAngle = atan2(toCursor[1], toCursor[0]);

    _cursorAngle = lastCursorAngle +
        atan2(sin(_cursorAngle - lastCursorAngle),
            cos(_cursorAngle - lastCursorAngle));

    var deltaAngle = _cursorAngle - _startCursorAngle;

    handle.showSlice(_startHandleAngle, _startHandleAngle + deltaAngle);

    for (final rotatingBone in _bones) {
      rotatingBone.bone.rotation = rotatingBone.startAngle + deltaAngle;
    }
  }

  @override
  void complete() {
    handle.hideSlice();
  }

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    var toCursor = Vec2D.subtract(
        Vec2D(), details.artboardWorld.current, handle.translation);
    _cursorAngle = _startCursorAngle = atan2(toCursor[1], toCursor[0]);

    var bones = <Bone>{};

    for (final item in items) {
      if (item is StageJoint) {
        item.component.forEachBone((bone) {
          bones.add(bone);
          return true;
        });
      } else if (item is StageBone) {
        bones.add(item.component);
      }
    }
    var topBones = topComponents(bones);
    _bones = topBones.map((bone) => _RotatingBone(bone)).toList();

    // Remove any items in the set that are in this hierarchy. Important to not
    // allow further transformers from double transforming these items.
    items.removeWhere((item) {
      if (item is StageJoint) {
        return true;
      }
      if (item.component is! Component) {
        return false;
      }
      return isChildOf(item.component as Component, topBones);
    });

    return _bones.isNotEmpty;
  }
}
