import 'package:flutter/foundation.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/draw_rules.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/clipping_shape.dart';
import 'package:rive_core/src/generated/shapes/clipping_shape_base.dart';
import 'package:rive_core/src/generated/transform_component_base.dart';
export 'package:rive_core/src/generated/transform_component_base.dart';

abstract class TransformComponent extends TransformComponentBase {
  /// Draw rules saved against this transform component, inherited by children.
  DrawRules _drawRules;

  DrawRules get drawRules => _drawRules;

  List<ClippingShape> _clippingShapes;
  Iterable<ClippingShape> get clippingShapes => _clippingShapes;
  // -> editor-only
  final Event clippingShapesChanged = Event();
  final Event drawRulesChanged = Event();
  // <- editor-only

  // -> editor-only
  void markBoundsChanged() {
    _delegate?.boundsChanged();
  }

  void recomputeParentExpandableBounds() {
    // TODO: reconsider the escapeHatch. Make this work via some form of
    // settling process that runs the recompute when the dag has next validated
    // (if a validation is in progress).

    int escapeHatch = 1000;
    for (ContainerComponent p = this;
        escapeHatch > 0 && p != null;
        p = p.parent, escapeHatch--) {
      if (p.isExpandable) {
        // N.B. Hard assumption an expandable is a TransformComponent.
        assert(p is TransformComponent);
        (p as TransformComponent).markBoundsChanged();
      }
    }
  }

  BoundsDelegate _delegate;
  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }

  final Event _worldTransformChanged = Event();
  Listenable get worldTransformChanged => _worldTransformChanged;
  // <- editor-only

  double _renderOpacity = 0;
  double get renderOpacity => _renderOpacity;

  final Mat2D worldTransform = Mat2D();
  final Mat2D transform = Mat2D();

  Vec2D get translation => Vec2D.fromValues(x, y);
  Vec2D get worldTranslation =>
      Vec2D.fromValues(worldTransform[4], worldTransform[5]);

  double get x;
  double get y;
  set x(double value);
  set y(double value);

  @override
  void update(int dirt) {
    if (dirt & ComponentDirt.transform != 0) {
      updateTransform();
    }
    if (dirt & ComponentDirt.worldTransform != 0) {
      updateWorldTransform();
    }
  }

  void updateTransform() {
    if (rotation != 0) {
      Mat2D.fromRotation(transform, rotation);
    } else {
      Mat2D.identity(transform);
    }
    transform[4] = x;
    transform[5] = y;

    Mat2D.scaleByValues(transform, scaleX, scaleY);
  }

  // TODO: when we have layer effect renderers, this will need to render 1 for
  // layer effects.
  double get childOpacity => _renderOpacity;

  Vec2D get scale => Vec2D.fromValues(scaleX, scaleY);
  set scale(Vec2D value) {
    scaleX = value[0];
    scaleY = value[1];
  }

  @mustCallSuper
  void updateWorldTransform() {
    _renderOpacity = opacity;
    if (parent is TransformComponent) {
      var parentNode = parent as TransformComponent;
      _renderOpacity *= parentNode.childOpacity;
      Mat2D.multiply(worldTransform, parentNode.worldTransform, transform);
    } else {
      Mat2D.copy(worldTransform, transform);
    }
    // -> editor-only
    _delegate?.boundsChanged();
    _worldTransformChanged?.notify();
    // <- editor-only
  }

  void calculateWorldTransform() {
    var parent = this.parent;
    final chain = <TransformComponent>[this];

    while (parent != null) {
      if (parent is TransformComponent) {
        chain.insert(0, parent);
      }
      parent = parent.parent;
    }
    for (final item in chain) {
      item.updateTransform();
      item.updateWorldTransform();
    }
  }

  // -> editor-only

  /// Set [guaranteeInvertable] to true if you want a transform that
  // can definitely be inverted. This forces the matrix to not contain 0 scale
  // in either axis.
  Mat2D computeWorldTransform({bool guaranteeInvertable = false}) {
    final chain = <TransformComponent>[this];
    var parent = this.parent;
    while (parent != null) {
      if (parent is TransformComponent) {
        chain.insert(0, parent);
      }
      parent = parent.parent;
    }
    Mat2D world;
    for (final item in chain) {
      var local = Mat2D();
      if (item.rotation != 0) {
        Mat2D.fromRotation(local, item.rotation);
      } else {
        Mat2D.identity(local);
      }
      local[4] = item.x;
      local[5] = item.y;

      var sx = item.scaleX;
      var sy = item.scaleY;
      if (guaranteeInvertable) {
        if (sx == 0) {
          sx = 0.01;
        }
        if (sy == 0) {
          sy = 0.01;
        }
      }
      Mat2D.scaleByValues(local, sx, sy);

      if (world == null) {
        world = local;
      } else {
        Mat2D.multiply(world, world, local);
      }
    }
    return world;
  }
  // <- editor-only

  @override
  void buildDependencies() {
    super.buildDependencies();
    parent?.addDependent(this);
  }

  void markTransformDirty() {
    if (!addDirt(ComponentDirt.transform)) {
      return;
    }
    markWorldTransformDirty();
  }

  void markWorldTransformDirty() {
    addDirt(ComponentDirt.worldTransform, recurse: true);
  }

  @override
  void rotationChanged(double from, double to) {
    markTransformDirty();
  }

  @override
  void scaleXChanged(double from, double to) {
    markTransformDirty();
  }

  @override
  void scaleYChanged(double from, double to) {
    markTransformDirty();
  }

  @override
  void opacityChanged(double from, double to) {
    markTransformDirty();
  }

  @override
  void parentChanged(ContainerComponent from, ContainerComponent to) {
    super.parentChanged(from, to);
    markWorldTransformDirty();

    // -> editor-only
    // Let any old node parent know it needs to re-compute its bounds. Let new
    // node parents know they need to recompute their bounds.
    if (from is TransformComponent) {
      from.recomputeParentExpandableBounds();
    }
    if (to is TransformComponent) {
      to.recomputeParentExpandableBounds();
    }
    // <- editor-only
  }

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    switch (child.coreType) {
      case DrawRulesBase.typeKey:
        _drawRules = child as DrawRules;
        // -> editor-only
        artboard?.markNaturalDrawOrderDirty();
        drawRulesChanged.notify();
        // <- editor-only
        break;
      case ClippingShapeBase.typeKey:
        _clippingShapes ??= <ClippingShape>[];
        _clippingShapes.add(child as ClippingShape);
        addDirt(ComponentDirt.clip, recurse: true);
        // -> editor-only
        clippingShapesChanged.notify();
        // <- editor-only
        break;
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    switch (child.coreType) {
      case DrawRulesBase.typeKey:
        if (_drawRules == child as DrawRules) {
          _drawRules = null;
          // -> editor-only
          artboard?.markNaturalDrawOrderDirty();
          drawRulesChanged.notify();
          // <- editor-only
        }
        break;
      case ClippingShapeBase.typeKey:
        if (_clippingShapes != null) {
          _clippingShapes.remove(child as ClippingShape);
          if (_clippingShapes.isEmpty) {
            _clippingShapes = null;
          }
          addDirt(ComponentDirt.clip, recurse: true);
          // -> editor-only
          clippingShapesChanged.notify();
          // <- editor-only
        }
        break;
    }
  }

  // -> editor-only

  /// Compensate the world transform of this Node such that we remain in the
  /// same WorldTransform once the parent's WorldTransform updates. Basically:
  /// the parent has moved, our WorldTransform is cached at our current
  /// transformation. Use this to compute the inverse to the new
  /// ParentWorldTransform to keep us in the same visual position after the
  /// update cycle completes.
  void compensate() {
    assert(parent != null, 'can\'t compensate without parents');

    // Default the parentWorld to the identity, this works for the Artboard case
    // (an Artboard is not a Node and is in world space). We should be mindful
    // of this catching other non Node parents (are there any?).
    var parentWorld = Mat2D();
    if (parent is TransformComponent) {
      var nodeParent = parent as TransformComponent;
      parentWorld = nodeParent.computeWorldTransform();
    }

    var parentWorldInverse = Mat2D();
    if (!Mat2D.invert(parentWorldInverse, parentWorld)) {
      return;
    }
    var local = Mat2D();
    Mat2D.multiply(local, parentWorldInverse, worldTransform);

    var components = TransformComponents();
    Mat2D.decompose(local, components);
    scaleX = components.scaleX;
    scaleY = components.scaleY;
    rotation = components.rotation;
    x = components.x;
    y = components.y;
  }
  // <- editor-only

  @override
  void buildDrawOrder(
      List<Drawable> drawables, DrawRules rules, List<DrawRules> allRules) {
    if (drawRules != null) {
      // -> editor-only
      drawRules.parentRules = rules;
      // <- editor-only

      // ignore: parameter_assignments
      rules = drawRules;
      allRules.add(rules);
    }
    super.buildDrawOrder(drawables, rules, allRules);
  }
}
