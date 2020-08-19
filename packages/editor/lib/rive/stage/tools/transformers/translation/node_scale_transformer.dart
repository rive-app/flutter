import 'dart:collection';
import 'dart:math';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_scale_handle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/utilities.dart';

/// Transformer that rotates [StageItem]'s with underlying [Node] components.
class NodeScaleTransformer extends StageTransformer {
  Iterable<Node> _nodes;

  /// The scale transform is applied to world coordinates and then decomposed
  /// into each object's parent's transform. This means that the scale must be
  /// applied to the X and Y directly, not the transformed (rotated) X & Y.
  /// Scale is inherently applied last so we don't need to rotate the lock axis
  /// into world transform space.
  final Vec2D lockAxis;
  final StageScaleHandle handle;
  final TransformComponents transformComponents = TransformComponents();
  final StatefulShortcutAction<bool> proportionalScaleShortcut;

  final _inHandleSpace = HashMap<Node, Mat2D>();

  NodeScaleTransformer({
    this.handle,
    this.lockAxis,
    this.proportionalScaleShortcut,
  }) {
    Mat2D.decompose(handle.transform, transformComponents);
  }

  @override
  void advance(DragTransformDetails details) {
    var constraintedDelta = details.artboardWorld.delta;
    if (lockAxis != null) {
      var d = Vec2D.dot(constraintedDelta, lockAxis);
      constraintedDelta = Vec2D.fromValues(lockAxis[0] * d, lockAxis[1] * d);
    }
    var constraintedDeltaX = constraintedDelta[0];
    var constraintedDeltaY = constraintedDelta[1];

    // Lock scale if shortcut is detected and we're locked on an axis
    if (lockAxis != null &&
        proportionalScaleShortcut != null &&
        proportionalScaleShortcut.value) {
      if (constraintedDeltaX == 0) {
        constraintedDeltaX = constraintedDeltaY;
      } else if (constraintedDeltaY == 0) {
        constraintedDeltaY = constraintedDeltaX;
      }
    }

    transformComponents.scaleX += constraintedDeltaX * 0.01;
    transformComponents.scaleY -= constraintedDeltaY * 0.01;

    var transform = Mat2D();
    Mat2D.compose(transform, transformComponents);

    for (final node in _nodes) {
      var inHandleSpace = _inHandleSpace[node];
      var nodeWorld = Mat2D.multiply(Mat2D(), transform, inHandleSpace);

      var toParent = Mat2D();
      if (node.parent is Node) {
        if (!Mat2D.invert(toParent, (node.parent as Node).worldTransform)) {
          Mat2D.identity(toParent);
        }
      }

      var local = Mat2D.multiply(Mat2D(), toParent, nodeWorld);
      var components = TransformComponents();
      Mat2D.decompose(local, components);

      // TODO: Figure out if we want to provide more specific thresholds for
      // scale and radian angles.
      if (threshold(node.x, components.x)) {
        node.x = components.x;
      }
      if (threshold(node.y, components.y)) {
        node.y = components.y;
      }

      if (threshold(node.scaleX, components.scaleX)) {
        node.scaleX = components.scaleX;
      }
      if (threshold(node.scaleY, components.scaleY)) {
        node.scaleY = components.scaleY;
      }

      var lastRotation = node.rotation;
      var rotation = lastRotation +
          atan2(sin(components.rotation - lastRotation),
              cos(components.rotation - lastRotation));
      if (threshold(node.rotation, rotation)) {
        node.rotation = rotation;
      }
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    _nodes = items.mapWhereType<Node>((element) => element.component).toList();

    var handleTransform = handle.transform;

    // Compute a transform that puts any other world transform into handle
    // space. We use this to then store each node's transform in the handle
    // space such that when we multiply it by the new handle transform, we get
    // the new desired world transform of the node. We can then take that and
    // multiply by the node's parent's inverted world to get into parent space
    // which is where our local x, y, rotation, scale properties apply.
    var toHandle = Mat2D();
    if (!Mat2D.invert(toHandle, handleTransform)) {
      Mat2D.identity(toHandle);
    }

    _nodes = topComponents(_nodes);

    for (final node in _nodes) {
      _inHandleSpace[node] =
          Mat2D.multiply(Mat2D(), toHandle, node.worldTransform);
    }

    return _nodes.isNotEmpty;
  }
}
