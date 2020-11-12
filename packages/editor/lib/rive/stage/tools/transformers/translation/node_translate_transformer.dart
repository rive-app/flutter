import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_bone.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/utilities.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class NodeTranslateTransformer extends StageTransformer {
  NodeTranslateTransformer();

  @override
  void advance(DragTransformDetails details) {
    // Handled by snapper.
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    assert(
      items.isNotEmpty,
      'Initializing transformer on an empty set of items',
    );

    // Get Node and RootBones as TransformComponents (we can't just cast to
    // TransformComponent as there are some TransformComponents we're not
    // interested in, like non-root Bones).
    Iterable<TransformComponent> transformComponents = topComponents(items
        .where((item) => item.component is Node)
        .map((item) => item.component as TransformComponent));

    // Remove any items in the set that are in this hierarchy. Important to not
    // allow further transformers from double transforming these items.
    items.removeWhere((item) {
      if (item.component is! Component) {
        return false;
      }
      return isChildOf(item.component as Component, transformComponents);
    });

    if (transformComponents.isNotEmpty) {
      // get snapping context
      var snapper = details.artboard.stageItem.stage.snapper;
      snapper.add(
          transformComponents
              .map((tc) => TransformComponentSnappingItem(tc))
              .where((item) => item != null)
              .toList(), (item, exclusion) {
        if (exclusion.contains(item)) {
          return false;
        }
        // Filter out components that are not shapes or nodes, or not in the
        // active artboard
        final activeArtboard = details.artboard;
        if (item is StageShape || item is StageNode || item is StageArtboard) {
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

class TransformComponentSnappingItem extends SnappingItem {
  final Mat2D toParent;
  final Vec2D worldTranslation;
  final TransformComponent transformComponent;

  @override
  StageItem get stageItem => transformComponent.stageItem;

  factory TransformComponentSnappingItem(TransformComponent tc) {
    var artboard = tc.artboard;
    var world = artboard.transform(tc.parent is TransformComponent
        ? (tc.parent as TransformComponent).worldTransform
        : Mat2D());
    var inverse = Mat2D();
    if (!Mat2D.invert(inverse, world)) {
      return null;
    }
    return TransformComponentSnappingItem._(
      tc,
      inverse,
      Mat2D.getTranslation(
        artboard.transform(tc.worldTransform),
        Vec2D(),
      ),
    );
  }

  TransformComponentSnappingItem._(
      this.transformComponent, this.toParent, this.worldTranslation);
  @override
  void translateWorld(Vec2D diff) {
    var world = Vec2D.add(Vec2D(), worldTranslation, diff);

    var local = Vec2D.transformMat2D(Vec2D(), world, toParent);
    transformComponent.x = local[0];
    transformComponent.y = local[1];
    if (ShortcutAction.freezeToggle.value) {
      for (final child in transformComponent.children) {
        if (child is TransformComponent) {
          child.compensate();
        }
      }
    }
  }

  @override
  void addSources(SnappingAxes snap, bool isSingleSelection) {
    // When freezing, just add the centroid/pivot of the component as the
    // snapping source.
    if (ShortcutAction.freezeToggle.value) {
      snap.addVec(Vec2D.add(Vec2D(), transformComponent.artboard.originWorld,
          transformComponent.worldTranslation));
      return;
    }

    var stageItem = transformComponent.stageItem;
    if (stageItem is StageNode) {
      snap.addVec(AABB.center(Vec2D(), stageItem.aabb));
    } else if (stageItem is StageBone) {
      // This is a root bone, add the base/tip as snap sources.
      var bone = stageItem.component;
      snap.addVec(Mat2D.getTranslation(
        bone.artboard.transform(bone.tipWorldTransform),
        Vec2D(),
      ));
      snap.addVec(Mat2D.getTranslation(
        bone.artboard.transform(bone.worldTransform),
        Vec2D(),
      ));
    } else if (isSingleSelection && stageItem.obb != null) {
      var obb = stageItem.obb;
      if (obb.bounds.isEmpty) {
        // If the bounds are empty, just add the single point of translation of
        // this object.
        dynamic component = stageItem.component;
        if (component is TransformComponent && component.artboard != null) {
          snap.addVec(
              component.artboard.renderTranslation(component.worldTranslation));
        }
        return;
      }
      var poly = obb.poly;

      snap.addPoint(poly[0], poly[1]);
      snap.addPoint(poly[2], poly[3]);
      snap.addPoint(poly[4], poly[5]);
      snap.addPoint(poly[6], poly[7]);
      snap.addVec(obb.center);
    } else {
      snap.accumulateBounds(stageItem.aabb);
    }
  }
}
