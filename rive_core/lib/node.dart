import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';

import 'math/mat2d.dart';
import 'src/generated/node_base.dart';
export 'src/generated/node_base.dart';

abstract class NodeDelegate {
  void nodeTransformed();
  void nodeBoundsChanged();
}

class Node extends NodeBase {
  final Mat2D transform = Mat2D();
  final Mat2D worldTransform = Mat2D();

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

  void worldTransformed() {}

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

  void updateWorldTransform() {
    _renderOpacity = opacity;
    if (parent is Node) {
      var parentNode = parent as Node;
      _renderOpacity *= parentNode.childOpacity;
      Mat2D.multiply(worldTransform, parentNode.worldTransform, transform);
    } else {
      Mat2D.copy(worldTransform, transform);
    }

    worldTransformed();
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
    addDirt(ComponentDirt.worldTransform, recurse: true);
  }

  @override
  void xChanged(double from, double to) {
    markTransformDirty();
    super.xChanged(from, to);
  }

  @override
  void yChanged(double from, double to) {
    markTransformDirty();
    super.yChanged(from, to);
  }

  @override
  void rotationChanged(double from, double to) {
    markTransformDirty();
    super.rotationChanged(from, to);
  }

  @override
  void scaleXChanged(double from, double to) {
    markTransformDirty();
    super.scaleXChanged(from, to);
  }

  @override
  void scaleYChanged(double from, double to) {
    markTransformDirty();
    super.scaleYChanged(from, to);
  }

  @override
  void opacityChanged(double from, double to) {
    markTransformDirty();
    super.opacityChanged(from, to);
  }
}
