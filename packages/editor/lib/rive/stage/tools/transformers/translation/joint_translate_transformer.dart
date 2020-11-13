import 'dart:math';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_bone.dart';
import 'package:rive_editor/rive/stage/items/stage_joint.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_translate_transformer.dart';
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
    Set<Bone> transformAsNode = {};
    for (final item in items) {
      if (item is StageRootJoint ||
          (item is StageBone && item.component is RootBone)) {
        bones.add(item.component as RootBone);
        transformAsNode.add(item.component as RootBone);
      } else if (item is StageJoint) {
        bones.add(item.component);
      } else if (item is StageBone &&
          item.component.coreType == BoneBase.typeKey) {
        bones.add(item.component.parent as Bone);
        boneChildToInclude[item.component.parent as Bone] = item.component;
      }
    }

    var topBones = topComponents(bones);

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

      var tcSnappingItems = <TransformComponentSnappingItem>[];
      var jointSnappingItems = <_JointSnappingItem>[];
      for (final bone in bones) {
        if (bone is RootBone && transformAsNode.contains(bone)) {
          var item = TransformComponentSnappingItem(bone);
          if (item != null) {
            tcSnappingItems.add(item);
          }
        } else {
          jointSnappingItems.add(_JointSnappingItem(
            bone.stageItem as StageBone,
            boneChildToInclude[bone],
            boneTips,
          ));
        }
      }

      bool _filterSnapSource(StageItem item, Set<StageItem> exclusion) {
        // If it's a stage joint and the matching stageBone is excluded, don't
        // include the joint.
        if (item is StageJoint &&
            exclusion.contains(item.component.stageItem)) {
          return false;
        } else if (exclusion.contains(item)) {
          return false;
        }
        // Filter out components that are not shapes or nodes, or not in the
        // active artboard
        final activeArtboard = details.artboard;
        if (item is StageShape ||
            item is StageNode ||
            item is StageJoint ||
            item is StageArtboard) {
          final itemArtboard = (item.component as Component).artboard;
          return activeArtboard == itemArtboard;
        }
        return false;
      }

      // Root bones transform as TransformComponents, so we add them separately.
      // We do this here instead of in NodeTranslateTransformer as we want to
      // filter the same snapping sources as a joint.
      if (tcSnappingItems.isNotEmpty) {
        snapper.add(tcSnappingItems, _filterSnapSource);
      }

      // The rest (if any) will be joints.
      if (jointSnappingItems.isNotEmpty) {
        snapper.add(jointSnappingItems, _filterSnapSource);
      }
      return true;
    }
    return false;
  }
}

class _JointSnappingItem extends SnappingItem {
  final StageBone stageBone;
  final Map<Bone, Vec2D> boneTips;
  final Bone childBone;

  @override
  StageItem get stageItem => stageBone.tipJoint;

  _JointSnappingItem(
    this.stageBone,
    this.childBone,
    this.boneTips,
  );

  @override
  void translateWorld(Vec2D diff) {
    var component = stageBone.component;

    // Since we're translating the bone's tip, we also need to compensate the
    // children's children. We do this by propagating the depth (starting at 0
    // here) to the chain translator.
    _translateChain(component, diff, ShortcutAction.freezeToggle.value, 0);
  }

  void _translateChain(
      Bone bone, Vec2D worldTranslation, bool freeze, int depth) {
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

    var lastRotation = bone.rotation;
    var rotation = atan2(diff[1], diff[0]);
    bone.rotation +=
        atan2(sin(rotation - lastRotation), cos(rotation - lastRotation));
    bone.calculateWorldTransform();

    for (final child in bone.children) {
      if (child.coreType == BoneBase.typeKey) {
        var childBone = child as Bone;
        childBone.updateTransform();
        childBone.updateWorldTransform();
        _translateChain(
          childBone,
          // If we're freezing, don't apply any offset to children
          freeze ? Vec2D() : worldTranslation,
          freeze,
          depth + 1,
        );
      } else if (freeze && child is TransformComponent && depth < 2) {
        child.compensate();
      }
    }
  }

  @override
  void addSources(SnappingAxes snap, bool isSingleSelection) {
    var bone = stageBone.component;
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
