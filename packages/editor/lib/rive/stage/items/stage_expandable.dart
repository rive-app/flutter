import 'dart:math';

import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_core/shapes/path.dart' as core;

/// An abstraction to be mixed into [StageItem] to give it expandable abiltiies
/// with regards to Node UX.
abstract class StageExpandable<T extends Node> {
  T get component;

  AABB get aabb;
  set aabb(AABB value);

  OBB get obb;
  set obb(OBB value);

  bool get hasSelectionFlags;
  Stage get stage;

  bool _boundsValid = false;

  void boundsChanged() {
    if (stage == null) {
      // This can happen if items are deleted in one op and one dependent item
      // tells the other to update its bounds while this item is also being
      // deleted.
      return;
    }
    _boundsValid = false;

    if (ShortcutAction.freezeToggle.value) {
      // if freeze is turned on, immediately compute bounds...
      computeBounds();
    } else {
      stage.debounce(computeBounds,
          duration: Duration(
              milliseconds:
                  recomputeBoundsMin + Random().nextInt(recomputeBoundsJitter)),
          reset: true);
    }
  }

  static const int recomputeBoundsMin = 50;
  static const int recomputeBoundsJitter = 200;
  static const int recomputeBoundsMax =
      recomputeBoundsMin + recomputeBoundsJitter;

  void cancelBoundsChanged() => stage.cancelDebounce(computeBounds);

  bool computeBounds() {
    if (component?.artboard == null) {
      return false;
    }
    var artboard = component.artboard;
    var worldTransform = component.worldTransform;

    // Transform to get into local space of this node.
    var inverseWorld = Mat2D();
    if (!Mat2D.invert(inverseWorld, worldTransform)) {
      // If inversion fails, it's because one of the axes have 0 scale causing a
      // 0 determinant which fails inversion. We use a hack to compute a
      // non-zero determinant version and then reset it (ugh hideous but only
      // happens in the editor). This allows the bounding box to be drawn
      // (somewhat) correctly.
      // component.calculateWorldTransform();
      var invertableWorldTransform =
          component.computeWorldTransform(guaranteeInvertable: true);
      if (!Mat2D.invert(inverseWorld, invertableWorldTransform)) {
        Mat2D.identity(inverseWorld);
      }
    }

    AABB accumulatedBounds;
    component.forEachChild((component) {
      // When we have images we may want to have a generic interface for getting
      // the bounds, but for now we only have shapes.
      switch (component.coreType) {
        case BoneBase.typeKey:
        case RootBoneBase.typeKey:
          var bone = component as Bone;
          var localBoneTranslation = Vec2D.transformMat2D(
              Vec2D(), bone.worldTranslation, inverseWorld);
          var localBoneTip = Vec2D.transformMat2D(
              Vec2D(), bone.tipWorldTranslation, inverseWorld);

          if (accumulatedBounds == null) {
            accumulatedBounds =
                AABB.fromPoints([localBoneTranslation, localBoneTip]);
          } else {
            accumulatedBounds.expandToPoint(localBoneTranslation);
            accumulatedBounds.expandToPoint(localBoneTip);
          }
          break;
        default:
          if (component is core.Path) {
            var path = component;
            var bounds = path.computeBounds(inverseWorld);
            if (accumulatedBounds == null) {
              accumulatedBounds = bounds;
            } else {
              AABB.combine(accumulatedBounds, accumulatedBounds, bounds);
            }
          }
          break;
      }
      return true;
    });
    _boundsValid = true;

    // Were we able to accumulate bounds from our children? If not, we return
    // false such that the parent stage item can use some fall-back
    // visual/selectable state as nothing inside of it is selectable. For a node
    // this equates to showing the 'null' rectangle icon for the node.
    if (accumulatedBounds != null &&
        (accumulatedBounds.width > 0 || accumulatedBounds.height > 0)) {
      var artboardWorld = artboard.transform(worldTransform);
      // accumulatedBounds is in local node space so convert it to world for the
      // AABB.
      aabb = accumulatedBounds.transform(artboardWorld);

      // Store an OBB so we can draw and use that for accurate hit detection.
      obb = OBB(
        bounds: accumulatedBounds,
        transform: artboardWorld,
      );
      return true;
    }
    return false;
  }

  bool get shouldDrawBounds {
    return obb != null && hasSelectionFlags && _boundsValid;
  }

  bool isExpanded = false;
  StageItem parentStageItem;
  Iterable<StageExpandable> get allParentExpandables {
    List<StageExpandable> expandables = [this];
    for (var p = component.parent; p != null; p = p.parent) {
      if (p.stageItem is StageExpandable) {
        expandables.add(p.stageItem as StageExpandable);
      }
    }
    return expandables;
  }

  static StageItem findNonExpanded(StageItem item) {
    if (item.component == null) {
      return null;
    }

    StageItem last = item;
    for (var node = (item.component as Component).parentExpandable;
        node != null;
        node = node.parentExpandable) {
      var stageExpandable = node.stageItem as StageExpandable;
      if (stageExpandable.isExpanded) {
        return last;
      }
      last = stageExpandable as StageItem;
    }
    return last;
  }
}
