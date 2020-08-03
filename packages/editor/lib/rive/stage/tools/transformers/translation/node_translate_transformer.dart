import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/iterable.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class NodeTranslateTransformer extends StageTransformer {
  NodeTranslateTransformer({this.lockAxis, ValueNotifier<bool> snap})
      : _snap = snap ?? ValueNotifier<bool>(true);

  Iterable<Node> _nodes;
  final Vec2D lockAxis;
  Snapper _snapper;

  /// Should items snap while translating?
  final ValueNotifier<bool> _snap;

  /// Hide the handles while transforming across both axes, i.e. when not locked
  /// to one axis
  @override
  bool get hideHandles => lockAxis == null;

  @override
  void advance(DragTransformDetails details) {
    if (_snap.value) {
      _snapper.advance(details.world.current, lockAxis: lockAxis);
      return;
    }
    Map<Node, Mat2D> worldToParents = {};

    var failedInversion = Mat2D();
    // First assume we can use artboard level mouse move.
    var constraintedDelta = details.artboardWorld.delta;
    if (lockAxis != null) {
      var d = Vec2D.dot(constraintedDelta, lockAxis);
      constraintedDelta = Vec2D.fromValues(lockAxis[0] * d, lockAxis[1] * d);
    }
    for (final node in _nodes) {
      var delta = constraintedDelta;
      // If it's a node, we have to get into its parent's space as that's where
      // its translation lives.
      if (node.parent is Node) {
        var parentNode = node.parent as Node;
        var parentWorldInverse = worldToParents[parentNode];
        if (parentWorldInverse == null) {
          Mat2D inverse = Mat2D();
          if (!Mat2D.invert(inverse, parentNode.worldTransform)) {
            // If the inversion fails (0 scale?) then set the inverse as a
            // failed inversion so we don't attempt to re-process it.
            worldToParents[parentNode] = failedInversion;
          } else {
            worldToParents[parentNode] = parentWorldInverse = inverse;
          }
        }

        // Only process items with valid transform spaces.
        if (parentWorldInverse == null ||
            parentWorldInverse == failedInversion) {
          continue;
        }
        delta = Vec2D.transformMat2(Vec2D(), delta, parentWorldInverse);
      }

      // Finally apply the delta (or transformed delta).
      node.x += delta[0];
      node.y += delta[1];
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

    _nodes =
        topComponents(items.mapWhereType<Node>((element) => element.component));
    if (_nodes.isNotEmpty) {
      _snapper = Snapper.build(details.world.current, _nodes, (item) {
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
