import 'dart:collection';
import 'dart:math';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_scale_handle.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/utilities.dart';

/// Transformer that rotates [StageItem]'s with underlying [TransformComponent]
/// components.
class NodeScaleTransformer extends StageTransformer {
  Iterable<TransformComponent> _transformComponents;

  /// The scale transform is applied to world coordinates and then decomposed
  /// into each object's parent's transform. This means that the scale must be
  /// applied to the X and Y directly, not the transformed (rotated) X & Y.
  /// Scale is inherently applied last so we don't need to rotate the lock axis
  /// into world transform space.
  final Vec2D lockAxis;
  final StageScaleHandle handle;
  final TransformComponents transformComponents = TransformComponents();
  final StatefulShortcutAction<bool> proportionalScaleShortcut;

  // Record the scales for all the top nodes when intializing the tool so that
  // the proportional scale shortcut knows what ratios to scale to
  Vec2D _proportionalScale;

  // Tracks the scale at the time just before proportional scaling is
  // activated, so we can return to the last scale if turns off
  Vec2D _previousScale;

  final _inHandleSpace = HashMap<TransformComponent, Mat2D>();

  NodeScaleTransformer({
    this.handle,
    this.lockAxis,
    this.proportionalScaleShortcut,
  }) {
    Mat2D.decompose(handle.transform, transformComponents);
  }

  @override
  void advance(DragTransformDetails details) {
    if (details != null) {
      var constraintedDelta = details.artboardWorld.delta;
      if (lockAxis != null) {
        var d = Vec2D.dot(constraintedDelta, lockAxis);
        constraintedDelta = Vec2D.fromValues(lockAxis[0] * d, lockAxis[1] * d);
      }
      var constraintedDeltaX = constraintedDelta[0];
      var constraintedDeltaY = constraintedDelta[1];

      // Lock scale if shortcut is detected and we're locked on an axis
      if (lockAxis != null &&
          _proportionalScale != null &&
          proportionalScaleShortcut != null &&
          proportionalScaleShortcut.value) {
        if (constraintedDeltaX == 0) {
          // Calculate the proportion delta x change
          transformComponents.scaleX = transformComponents.scaleY /
              _proportionalScale[1] *
              _proportionalScale[0];
        } else if (constraintedDeltaY == 0) {
          // Calculate the proportion delta y change
          transformComponents.scaleY = transformComponents.scaleX /
              _proportionalScale[0] *
              _proportionalScale[1];
        }
      }

      transformComponents.scaleX += constraintedDeltaX * 0.01;
      transformComponents.scaleY -= constraintedDeltaY * 0.01;
    }

    var transform = Mat2D();
    Mat2D.compose(transform, transformComponents);

    for (final tc in _transformComponents) {
      var inHandleSpace = _inHandleSpace[tc];
      var nodeWorld = Mat2D.multiply(Mat2D(), transform, inHandleSpace);

      var toParent = Mat2D();
      if (tc.parent is TransformComponent) {
        if (!Mat2D.invert(
            toParent, (tc.parent as TransformComponent).worldTransform)) {
          Mat2D.identity(toParent);
        }
      }

      var local = Mat2D.multiply(Mat2D(), toParent, nodeWorld);
      var components = TransformComponents();
      Mat2D.decompose(local, components);

      // TODO: Figure out if we want to provide more specific thresholds for
      // scale and radian angles.
      if (threshold(tc.x, components.x)) {
        tc.x = components.x;
      }
      if (threshold(tc.y, components.y)) {
        tc.y = components.y;
      }

      if (threshold(tc.scaleX, components.scaleX)) {
        tc.scaleX = components.scaleX;
      }
      if (threshold(tc.scaleY, components.scaleY)) {
        tc.scaleY = components.scaleY;
      }

      var lastRotation = tc.rotation;
      var rotation = lastRotation +
          atan2(sin(components.rotation - lastRotation),
              cos(components.rotation - lastRotation));
      if (threshold(tc.rotation, rotation)) {
        tc.rotation = rotation;
      }
    }
  }

  @override
  void complete() =>
      proportionalScaleShortcut?.removeListener(_advanceWithPrevious);

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    _transformComponents = items
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

    _transformComponents = topComponents(_transformComponents);

    // HACK: proportional scaling only activates with exactly one top component
    // selected
    if (_transformComponents.length == 1) {
      _proportionalScale = _transformComponents.first.scale;
      // Subscribe to keypress events on the shortcut action
      proportionalScaleShortcut?.addListener(_advanceWithPrevious);
    } else {
      _proportionalScale = null;
    }

    for (final tc in _transformComponents) {
      _inHandleSpace[tc] = Mat2D.multiply(Mat2D(), toHandle, tc.worldTransform);
    }

    return _transformComponents.isNotEmpty;
  }

  /// Advance using the previous scale details if there are any
  void _advanceWithPrevious() {
    // if the tool is activated, record the previous scale
    if (proportionalScaleShortcut.value) {
      _previousScale = Vec2D.clone(transformComponents.scale);

      final deltaY = transformComponents.scaleX - _proportionalScale[0];
      final deltaX = transformComponents.scaleY - _proportionalScale[1];

      transformComponents.scaleX += _proportionalScale[0] * deltaX;
      transformComponents.scaleY += _proportionalScale[1] * deltaY;
    }
    // otherwise, recalculate the current scale based on the recorded and wipe
    // the previous scale
    else {
      final deltaX = transformComponents.scaleX - _previousScale[0];
      final deltaY = transformComponents.scaleY - _previousScale[1];

      transformComponents.scaleX -= _previousScale[0] * deltaX;
      transformComponents.scaleY -= _previousScale[1] * deltaY;

      _previousScale = null;
    }
    advance(null);
  }
}
