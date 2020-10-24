import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/stage/items/stage_bone.dart';
import 'package:rive_editor/rive/stage/items/stage_joint.dart';
import 'package:rive_editor/rive/stage/items/stage_scale_handle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/utilities.dart';

class JointScaleTransformer extends StageTransformer {
  static const sensitivity = 0.01;
  Iterable<Bone> _bones;
  final Vec2D lockAxis;
  final StageScaleHandle handle;

  JointScaleTransformer({this.handle, this.lockAxis});

  @override
  void advance(DragTransformDetails details) {
    var constrainedDelta = details.artboardWorld.delta;
    if (lockAxis != null) {
      var d = Vec2D.dot(constrainedDelta, lockAxis);

      constrainedDelta = Vec2D.fromValues(lockAxis[0] * d, lockAxis[1] * d);
    }
    for (final bone in _bones) {
      Mat2D parentSpace;

      if (bone.parent is TransformComponent) {
        var parent = bone.parent as TransformComponent;
        parentSpace = Mat2D.clone(parent.worldTransform);
      } else {
        parentSpace = Mat2D();
      }

      if (!Mat2D.invert(
          parentSpace,
          Mat2D.multiply(Mat2D(), parentSpace,
              Mat2D.fromRotation(Mat2D(), bone.rotation)))) {
        continue;
      }

      var scale = Vec2D.transformMat2(Vec2D(), constrainedDelta, parentSpace);
      bone.scaleX += scale[0] * sensitivity;
      bone.scaleY -= scale[1] * sensitivity;
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    var bones = <Bone>{};

    for (final item in items) {
      if (item is StageJoint || item is StageBone) {
        bones.add(item.component as Bone);
      }
    }
    _bones = topComponents(bones);

    // Remove any items in the set that are in this hierarchy. Important to not
    // allow further transformers from double transforming these items.
    items.removeWhere((item) {
      if (item is StageJoint || item is StageBone) {
        return true;
      }
      if (item.component is! Component) {
        return false;
      }
      return isChildOf(item.component as Component, _bones);
    });

    return _bones.isNotEmpty;
  }
}
