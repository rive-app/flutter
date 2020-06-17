import 'package:flutter/foundation.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/node_base.dart';
import 'package:meta/meta.dart';
export 'package:rive_core/src/generated/node_base.dart';

class Node extends NodeBase {
  // -> editor-only
  final Event _worldTransformChanged = Event();
  Listenable get worldTransformChanged => _worldTransformChanged;
  // <- editor-only

  final Mat2D transform = Mat2D();
  final Mat2D worldTransform = Mat2D();
  BoundsDelegate _delegate;

  double _renderOpacity = 0;
  double get renderOpacity => _renderOpacity;

  @override
  void update(int dirt) {
    if (dirt & ComponentDirt.transform != 0) {
      updateTransform();
    }
    if (dirt & ComponentDirt.worldTransform != 0) {
      updateWorldTransform();
    }
  }

  Vec2D get translation => Vec2D.fromValues(x, y);
  Vec2D get worldTranslation =>
      Vec2D.fromValues(worldTransform[4], worldTransform[5]);

  /// Sets the position of the Node
  set translation(Vec2D pos) {
    x = pos[0];
    y = pos[1];
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

  @mustCallSuper
  void updateWorldTransform() {
    _renderOpacity = opacity;
    if (parent is Node) {
      var parentNode = parent as Node;
      _renderOpacity *= parentNode.childOpacity;
      Mat2D.multiply(worldTransform, parentNode.worldTransform, transform);
    } else {
      Mat2D.copy(worldTransform, transform);
    }
    _delegate?.boundsChanged();
    // -> editor-only
    _worldTransformChanged?.notify();
    // <- editor-only
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }

  void calculateWorldTransform() {
    var parent = this.parent;
    final chain = <Node>[this];

    while (parent != null) {
      if (parent is Node) {
        chain.insert(0, parent);
      }
      parent = parent.parent;
    }

    for (final item in chain) {
      item.updateTransform();
      item.updateWorldTransform();
    }
  }

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
  void xChanged(double from, double to) {
    markTransformDirty();
  }

  @override
  void yChanged(double from, double to) {
    markTransformDirty();
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
  }

  // -> editor-only

  /// Compensate the world transform of this Node such that we remain in the
  /// same WorldTransform once the parent's WorldTransform updates. Basically:
  /// the parent has moved, our WorldTransform is cached at our current
  /// transformation. Use this to compute the inverse to the new
  /// ParentWorldTransform to keep us in the same visual position after the
  /// update cycle completes.
  void compensate() {
    // TODO: can't compensate if we have an overrideWorldTransform (this plays
    // in when we get bones).
    assert(parent != null, 'can\'t compensate without parents');

    // Default the parentWorld to the identity, this works for the Artboard case
    // (an Artboard is not a Node and is in world space). We should be mindful
    // of this catching other non Node parents (are there any?).
    var parentWorld = Mat2D();
    if (parent is Node) {
      var nodeParent = parent as Node;
      nodeParent.calculateWorldTransform();
      parentWorld = nodeParent.worldTransform;
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
}
