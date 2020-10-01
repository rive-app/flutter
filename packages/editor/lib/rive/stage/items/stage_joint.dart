import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_handle.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_hideable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/bone_tool.dart';
import 'package:rive_editor/rive/stage/tools/transform_handle_tool.dart';

class StageJoint extends HideableStageItem<Bone>
    implements StageTransformable, TransfomHandleSelectionMutator {
  static const double hitRadius = BoneJointRenderer.radius + 3;
  static const double hitRadiusSquared = hitRadius * hitRadius;
  static const double _maxWorldJointSize =
      BoneJointRenderer.radius / BoneJointRenderer.minJointScale;
  Vec2D _worldTranslation;

  @override
  ValueNotifier<bool> get isShownNotifier => stage.showNodesNotifier;

  final Event _jointTransformChanged = Event();

  set worldTranslation(Vec2D value) {
    _worldTranslation = value;
    aabb = AABB.fromValues(
      _worldTranslation[0] - _maxWorldJointSize,
      _worldTranslation[1] - _maxWorldJointSize,
      _worldTranslation[0] + _maxWorldJointSize,
      _worldTranslation[1] + _maxWorldJointSize,
    );
    _jointTransformChanged.notify();
    stage?.updateBounds(this);
  }

  Vec2D get worldTranslation => _worldTranslation;

  
  @override
  StageItem get selectionTarget {
    return StageNode.findNonExpanded(this);
  }
  
  @override
  bool hitHiFi(Vec2D worldMouse) {
    var zoom = stage.viewZoom;
    if (zoom < BoneJointRenderer.minJointScale) {
      zoom /= BoneJointRenderer.minJointScale;
    }
    return Vec2D.squaredDistance(worldMouse, _worldTranslation) <=
        hitRadiusSquared / (zoom * zoom);
  }

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 3, inWorldSpace: false)];

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    var screen =
        Vec2D.transformMat2D(Vec2D(), _worldTranslation, stage.viewTransform);

    canvas.save();
    canvas.translate(screen[0].round() + 0.5, screen[1].round() + 0.5);

    BoneJointRenderer.draw(canvas, selectionState.value, stage.viewZoom);
    canvas.restore();
    // drawBounds(canvas, pass);
  }

  @override
  Mat2D get renderTransform =>
      component.artboard.transform(component.tipWorldTransform);

  @override
  Mat2D get worldTransform => component.tipWorldTransform;

  @override
  Listenable get worldTransformChanged => _jointTransformChanged;

  @override
  int get transformFlags {
    int flags = TransformFlags.x | TransformFlags.y;
    if (component.firstChildBone != null) {
      flags |= TransformFlags.rotation;
    }
    return flags;
  }

  @override
  void mutateTransformSelection(StageHandle handle, List<StageItem> selection) {
    if (handle.transformType == TransformFlags.y) {
      // When attempting to drag the Y axis, make sure to include the bone
      // itself.
      selection.add(component.stageItem);
    }
  }

  @override
  void addSnapTarget(SnappingAxes axes) {
    axes.addVec(_worldTranslation);
  }
}

class StageRootJoint extends StageJoint {
  @override
  int get transformFlags =>
      TransformFlags.x |
      TransformFlags.y |
      TransformFlags.rotation |
      TransformFlags.scaleX |
      TransformFlags.scaleY;
  @override
  void mutateTransformSelection(StageHandle handle, List<StageItem> selection) {
    // Intentionally empty as this doesn't mutate the selection like the super
    // (regular joint) does.
  }

  @override
  Mat2D get renderTransform =>
      component.artboard.transform(component.worldTransform);

  @override
  Mat2D get worldTransform => component.worldTransform;
}
