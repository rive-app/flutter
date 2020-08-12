import 'dart:math';
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
  @override
  void advance(DragTransformDetails details) {}

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    assert(
      items.isNotEmpty,
      'Initializing transformer on an empty set of items',
    );

    Map<Bone, Bone> boneChildToInclude = {};
    var bones = <Bone>{};
    Map<Bone, Vec2D> boneTips = {};
    for (final item in items) {
      if (item is StageJoint) {
        bones.add(item.component);
      } else if (item is StageBone &&
          item.component.coreType == BoneBase.typeKey) {
        bones.add(item.component.parent as Bone);
        boneChildToInclude[item.component.parent as Bone] = item.component;
      }
    }
    Iterable<Bone> topBones = topComponents(bones);

    if (topBones.isNotEmpty) {
      for (final bone in topBones) {
        boneTips[bone] = bone.tipWorldTranslation;
        bone.forAll((component) {
          if (component.coreType == BoneBase.typeKey) {
            var bone = component as Bone;
            boneTips[bone] = bone.tipWorldTranslation;
          }
          return true;
        });
      }
      var snapper = details.artboard.stageItem.stage.snapper;

      snapper.add(
          bones
              .map(
                (bone) => _JointSnappingItem(
                  bone,
                  boneChildToInclude[bone],
                  boneTips,
                ),
              )
              .toList(), (item) {
        // Filter out components that are not shapes or nodes, or not in the
        // active artboard
        final activeArtboard = details.artboard;
        if (item is StageShape || item is StageNode) {
          final itemArtboard = (item.component as Component).artboard;
          return activeArtboard == itemArtboard;
        }
        return false;
      });
      return true;
    }
    return false;
  }
}

class _JointSnappingItem extends SnappingItem {
  final Bone bone;
  final Map<Bone, Vec2D> boneTips;
  final Bone childBone;

  @override
  Component get component => bone;

  _JointSnappingItem(
    this.bone,
    this.childBone,
    this.boneTips,
  );

  @override
  void translateWorld(Vec2D diff) => _translateChain(bone, diff);

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
  void addSources(SnappingAxes snap, bool isSingleSelection) {
    snap.addVec(Mat2D.getTranslation(
      bone.artboard.transform(bone.tipWorldTransform),
      Vec2D(),
    ));
    if (childBone != null) {
      snap.addVec(Mat2D.getTranslation(
        childBone.artboard.transform(childBone.tipWorldTransform),
        Vec2D(),
      ));
    }
  }
}
