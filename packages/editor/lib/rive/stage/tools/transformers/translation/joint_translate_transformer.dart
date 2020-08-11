import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/stage/items/stage_bone.dart';
import 'package:rive_editor/rive/stage/items/stage_joint.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class JointTranslateTransformer extends StageTransformer {
  JointTranslateTransformer({this.lockAxis, ValueNotifier<bool> snap})
      : _snap = snap ?? ValueNotifier<bool>(true);

  Iterable<Bone> _bones;
  final Vec2D lockAxis;
  Vec2D startMouse;
  Snapper _snapper;

  /// Should items snap while translating?
  final ValueNotifier<bool> _snap;

  /// Hide the handles while transforming across both axes, i.e. when not locked
  /// to one axis
  @override
  bool get hideHandles => lockAxis == null;

  Map<Bone, Vec2D> boneTips = {};

  @override
  void advance(DragTransformDetails details) {
    if (_snap.value) {
      _snapper.advance(details.world.current, lockAxis: lockAxis);
      return;
    }
    // Map<TransformComponent, Mat2D> worldToParents = {};

    // var failedInversion = Mat2D();
    // First assume we can use artboard level mouse move.
    var constraintedDelta =
        Vec2D.subtract(Vec2D(), details.artboardWorld.current, startMouse);
    if (lockAxis != null) {
      var d = Vec2D.dot(constraintedDelta, lockAxis);
      constraintedDelta = Vec2D.fromValues(lockAxis[0] * d, lockAxis[1] * d);
    }
    for (final bone in _bones) {
      _translateChain(bone, constraintedDelta);
      //   var delta = constraintedDelta;
      //   // If it's a node, we have to get into its parent's space as that's where
      //   // its translation lives.

      //   if (bone.parent is TransformComponent) {
      //     var parentNode = bone.parent as TransformComponent;
      //     var parentWorldInverse = worldToParents[parentNode];
      //     if (parentWorldInverse == null) {
      //       Mat2D inverse = Mat2D();
      //       if (!Mat2D.invert(inverse, parentNode.worldTransform)) {
      //         // If the inversion fails (0 scale?) then set the inverse as a
      //         // failed inversion so we don't attempt to re-process it.
      //         worldToParents[parentNode] = failedInversion;
      //       } else {
      //         worldToParents[parentNode] = parentWorldInverse = inverse;
      //       }
      //     }

      //     // Only process items with valid transform spaces.
      //     if (parentWorldInverse == null ||
      //         parentWorldInverse == failedInversion) {
      //       continue;
      //     }
      //     delta = Vec2D.transformMat2(Vec2D(), delta, parentWorldInverse);
      //   }

      //   var parentTip = Vec2D.transformMat2D(
      //       Vec2D(), Vec2D.fromValues(bone.length, 0), bone.transform);
      //   var tip = Vec2D.add(Vec2D(), parentTip, delta);

      //   var diffToBoneStart = Vec2D.subtract(Vec2D(), tip, bone.translation);
      //   bone.rotation = atan2(diffToBoneStart[1], diffToBoneStart[0]);
      //   bone.length = Vec2D.length(diffToBoneStart);

    }
  }

  void _translateChain(Bone bone, Vec2D worldTranslation) {
    // Translate this bone's tip and figure out rotation and length for this
    // bone. Go down the chain.
    var start = boneTips[bone];
    var tip = Vec2D.add(Vec2D(), start, worldTranslation);
    var base = bone.worldTranslation;

    if (bone.parent is TransformComponent) {
      Mat2D inverse = Mat2D();
      if (Mat2D.invert(
          inverse, (bone.parent as TransformComponent).worldTransform)) {
        base = Vec2D.transformMat2D(Vec2D(), base, inverse);
        tip = Vec2D.transformMat2D(Vec2D(), tip, inverse);
      }
    }

    var diff = Vec2D.subtract(Vec2D(), tip, base);
    var length = Vec2D.length(diff);
    bone.length = length / bone.scaleX;
    bone.rotation = atan2(diff[1], diff[0]);
    bone.calculateWorldTransform();

    for (final child in bone.children) {
      if (child.coreType == BoneBase.typeKey) {
        var childBone = child as Bone;
        childBone.updateTransform();
        childBone.updateWorldTransform();
        _translateChain(childBone, worldTranslation);
      }
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    assert(
      items.isNotEmpty,
      'Initializing transformer on an empty set of items',
    );
    startMouse = details.world.current;

    var bones = <Bone>{};
    for (final item in items) {
      if (item is StageJoint) {
        bones.add(item.component);
      } else if (item is StageBone &&
          item.component.coreType == BoneBase.typeKey) {
        bones.add(item.component.parent as Bone);
      }
    }
    _bones = topComponents(bones);

    if (_bones.isNotEmpty) {
      for (final bone in _bones) {
        boneTips[bone] = bone.tipWorldTranslation;
        bone.forAll((component) {
          if (component.coreType == BoneBase.typeKey) {
            var bone = component as Bone;
            boneTips[bone] = bone.tipWorldTranslation;
          }
          return true;
        });
      }
      _snapper = Snapper.build(details.world.current, _bones, (item) {
        // Filter out components that are not shapes or nodes, or not in the
        // active artboard
        final activeArtboard = details.artboard;
        if (_snap.value && (item is StageShape || item is StageNode)) {
          final itemArtboard = (item.component as Component).artboard;
          return activeArtboard == itemArtboard;
        }
        return false;
      });
      return true;
    }
    return false;
  }

  @override
  void draw(Canvas canvas) {
    if (_snap.value) {
      _snapper?.draw(canvas);
    }
  }
}
