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
  static const sensitivity = 0.01;
  Iterable<TransformComponent> _transformComponents;

  /// The scale transform is applied to world coordinates and then decomposed
  /// into each object's parent's transform. This means that the scale must be
  /// applied to the X and Y directly, not the transformed (rotated) X & Y.
  /// Scale is inherently applied last so we don't need to rotate the lock axis
  /// into world transform space.
  final Vec2D lockAxis;
  final StageScaleHandle handle;
  final TransformComponents transformComponents = TransformComponents();
  final TransformComponents transformComponentsProportional =
      TransformComponents();
  final StatefulShortcutAction<bool> proportionalScaleShortcut;

  // Record the scales for all the top nodes when intializing the tool so that
  // the proportional scale shortcut knows what ratios to scale to
  bool _proportionalScale = false;

  final _inHandleSpace = HashMap<TransformComponent, Mat2D>();

  final Mat2D _handleInverse = Mat2D();
  double _ratio;

  NodeScaleTransformer({
    this.handle,
    this.lockAxis,
    this.proportionalScaleShortcut,
  }) {
    Mat2D.decompose(handle.transform, transformComponents);
    TransformComponents.copy(
        transformComponentsProportional, transformComponents);
    Mat2D.invert(_handleInverse, handle.transform);

    _ratio = transformComponents.scaleX / transformComponents.scaleY;
  }

  @override
  void advance(DragTransformDetails details) {
    if (details != null) {
      var constrainedDelta = details.artboardWorld.delta;
      // Reconsider when the ScaleTool is enable that allows scaling without a
      // lock axis (we may want to project to the closest handle, x/y). This
      // calculates the direction the scale proportional op should go (up/down).
      // We accumulate two sets of transform components and toggle which one to
      // use depending on whether the proprotional scale hotkey is down.

      double proportionalScaleDirection = 1;
      if (lockAxis != null) {
        var d = Vec2D.dot(constrainedDelta, lockAxis);
        proportionalScaleDirection = d.sign;
        constrainedDelta = Vec2D.fromValues(lockAxis[0] * d, lockAxis[1] * d);
      }

      var scale =
          Vec2D.transformMat2(Vec2D(), constrainedDelta, _handleInverse);

      transformComponents.scaleX += scale[0] * sensitivity;
      transformComponents.scaleY -= scale[1] * sensitivity;

      var equalScale = Vec2D.length(scale) * sensitivity;

      transformComponentsProportional.scaleX +=
          equalScale * _ratio * proportionalScaleDirection;
      transformComponentsProportional.scaleY +=
          equalScale * proportionalScaleDirection;
    }

    var transform = Mat2D();
    Mat2D.compose(
        transform,
        _proportionalScale
            ? transformComponentsProportional
            : transformComponents);

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
    proportionalScaleShortcut?.addListener(_advanceWithPrevious);
    _proportionalScale = proportionalScaleShortcut?.value ?? false;

    for (final tc in _transformComponents) {
      _inHandleSpace[tc] = Mat2D.multiply(Mat2D(), toHandle, tc.worldTransform);
    }

    return _transformComponents.isNotEmpty;
  }

  /// Advance using the previous scale details if there are any
  void _advanceWithPrevious() {
    _proportionalScale = proportionalScaleShortcut.value;
    advance(null);
  }
}
