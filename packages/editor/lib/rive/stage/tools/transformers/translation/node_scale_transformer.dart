import 'dart:collection';
import 'dart:math';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/items/stage_scale_handle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/iterable.dart';
import 'package:utilities/utilities.dart';

/// Transformer that rotates [StageItem]'s with underlying [Node] components.
class NodeScaleTransformer extends StageTransformer {
  List<Node> _nodes;
  final Vec2D lockAxis;
  final StageScaleHandle handle;
  final TransformComponents transformComponents = TransformComponents();

  final HashMap<Node, Mat2D> _inHandleSpace = HashMap<Node, Mat2D>();

  NodeScaleTransformer({this.handle, this.lockAxis}) {
    Mat2D.decompose(handle.transform, transformComponents);
  }

  @override
  void advance(DragTransformDetails details) {
    var constraintedDelta = details.artboardWorld.delta;
    if (lockAxis != null) {
      var d = Vec2D.dot(constraintedDelta, lockAxis);
      constraintedDelta = Vec2D.fromValues(lockAxis[0] * d, lockAxis[1] * d);
    }
    transformComponents.scaleX += constraintedDelta[0] * 0.01;
    transformComponents.scaleY -= constraintedDelta[1] * 0.01;

    var transform = Mat2D();
    Mat2D.compose(transform, transformComponents);
    for (final node in _nodes) {
      var inHandleSpace = _inHandleSpace[node];
      if (inHandleSpace == null) {
        // directly manipulate the node.
        node.scaleX = transformComponents.scaleX;
        node.scaleY = transformComponents.scaleY;
        continue;
      }
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

    outerLoop:
    for (int i = 0; i < _nodes.length; i++) {
      var node = _nodes[i];

      var parent = node.parent;
      while (parent is Node) {
        if (_nodes.contains(parent)) {
          _nodes.removeAt(i);
          i--;
          continue outerLoop;
        }
        parent = parent.parent;
      }

      if (Mat2D.areEqual(handleTransform, node.worldTransform)) {
        // The node and handle have the same transform, we can optimize by
        // directly manipulating the transform components of the node.
        continue;
      }

      // Compute node's world in handle world space
      _inHandleSpace[node] =
          Mat2D.multiply(Mat2D(), toHandle, node.worldTransform);
    }
    return _nodes.isNotEmpty;
  }
}
