import 'dart:collection';
import 'dart:math';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_rotation_handle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/utilities.dart';

/// Transformer that rotates [StageItem]'s with underlying [Node] components.
class NodeRotateTransformer extends StageTransformer {
  Iterable<TransformComponent> _nodes;
  final StageRotationHandle handle;
  final TransformComponents transformComponents = TransformComponents();

  final HashMap<TransformComponent, Mat2D> _inHandleSpace =
      HashMap<TransformComponent, Mat2D>();

  // Locks rotation to 45 degree increments
  final StatefulShortcutAction<bool> lockRotationShortcut;
  // Are we locked to 45 increments?
  bool _rotationLocked = false;

  NodeRotateTransformer({this.handle, this.lockRotationShortcut}) {
    Mat2D.decompose(handle.transform, transformComponents);
    _rotationLocked = lockRotationShortcut.value;
  }

  double _cursorAngle = 0;
  double _startCursorAngle = 0;

  @override
  void advance(DragTransformDetails details) {
    final rotatedComponents = TransformComponents.clone(transformComponents);
    final lockedRotatedComponents =
        TransformComponents.clone(transformComponents);
    // This happens if advance is triggered by the lock rotation key being
    // pressed. If the key is pressed, we need to remember the current rotation,
    // lock to the nearest 45. If the key is released, we need to go back to
    // the original rotation.
    if (details == null) {
      if (_rotationLocked) {
        rotatedComponents.rotation = lockedRotatedComponents.rotation =
            _snapToNearest45Degrees(
                rotatedComponents.rotation + _cursorAngle - _startCursorAngle);
      } else {
        rotatedComponents.rotation += _cursorAngle - _startCursorAngle;
      }
    } else {
      var toCursor = Vec2D.subtract(Vec2D(), details.artboardWorld.current,
          transformComponents.translation);
      var lastCursorAngle = _cursorAngle;
      _cursorAngle = atan2(toCursor[1], toCursor[0]);

      _cursorAngle = lastCursorAngle +
          atan2(sin(_cursorAngle - lastCursorAngle),
              cos(_cursorAngle - lastCursorAngle));

      var deltaAngle = _cursorAngle - _startCursorAngle;
      rotatedComponents.rotation += deltaAngle;

      lockedRotatedComponents.rotation =
          _snapToNearest45Degrees(rotatedComponents.rotation);
    }

    final transform = Mat2D();
    Mat2D.compose(transform,
        _rotationLocked ? lockedRotatedComponents : rotatedComponents);
    handle.showSlice(transformComponents.rotation, rotatedComponents.rotation);

    for (final node in _nodes) {
      var inHandleSpace = _inHandleSpace[node];
      var nodeWorld = Mat2D.multiply(Mat2D(), transform, inHandleSpace);

      var toParent = Mat2D();
      if (node.parent is TransformComponent) {
        if (!Mat2D.invert(
            toParent, (node.parent as TransformComponent).worldTransform)) {
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

      // This works because these _nodes are topped, if they were not we should
      // consider compensating only children that are not in _nodes.
      if (ShortcutAction.freezeToggle.value) {
        for (final child in node.children) {
          if (child is TransformComponent) {
            child.compensate();
          }
        }
      }
    }
  }

  @override
  void complete() {
    handle.hideSlice();
    lockRotationShortcut?.removeListener(_advanceWithLock);
  }

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    var toCursor = Vec2D.subtract(
        Vec2D(), details.artboardWorld.current, handle.translation);
    _cursorAngle = _startCursorAngle = atan2(toCursor[1], toCursor[0]);

    _nodes = items
        .mapWhereType<TransformComponent>((element) => element.component)
        .toList();

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

    lockRotationShortcut?.addListener(_advanceWithLock);

    for (final node in _nodes) {
      _inHandleSpace[node] =
          Mat2D.multiply(Mat2D(), toHandle, node.worldTransform);
    }
    return _nodes.isNotEmpty;
  }

  void _advanceWithLock() {
    _rotationLocked = lockRotationShortcut.value;
    advance(null);
  }

  // This takes an arbitrary angle and snaps it to the nearest 45 degrees
  double _snapToNearest45Degrees(double angle) {
    final lockInc = pi / 4;
    return (angle / lockInc).round() * lockInc;
  }
}
