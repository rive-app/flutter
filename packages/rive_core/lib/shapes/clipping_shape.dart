import 'package:core/core.dart';
import 'package:core/id.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/clipping_shape_base.dart';
export 'package:rive_core/src/generated/shapes/clipping_shape_base.dart';

enum ClipOp { intersection, difference }

class ClippingShape extends ClippingShapeBase {
  ClipOp get clipOp => ClipOp.values[clipOpValue];
  set clipOp(ClipOp value) => clipOpValue = value.index;

  Mat2D _shapeInverseWorld;
  Mat2D get shapeInverseWorld => _shapeInverseWorld;

  Shape _shape;
  Shape get shape => _shape;
  set shape(Shape value) {
    if (_shape == value) {
      return;
    }

    // -> editor-only

    // Handle when a shape is deleted. #1177
    _shape?.cancelWhenRemoved(remove);
    value?.whenRemoved(remove);

    // <- editor-only

    _shape = value;
    shapeId = value?.id;
  }

  // -> editor-only
  @override
  String get name => shape?.name;

  @override
  set name(String value) => shape?.name = value;

  @override
  Core eventDelegateFor(int propertyKey) {
    switch (propertyKey) {
      case ComponentBase.namePropertyKey:
        return shape;
      default:
        return this;
    }
  }
  // <- editor-only

  @override
  void clipOpValueChanged(int from, int to) {
    // In the future, if clipOp can change at runtime (animation), we may want
    // the shapes that use this as a clipping source to make them depend on this
    // clipping shape so we can add dirt to them directly.
    parent?.addDirt(ComponentDirt.clip, recurse: true);
  }

  @override
  void shapeIdChanged(Id from, Id to) {
    shape = context?.resolve(to);
  }

  @override
  void onAddedDirty() {
    super.onAddedDirty();
    if (shapeId != null) {
      shape = context?.resolve(shapeId);
    }
  }

  @override
  void buildDependencies() {
    super.buildDependencies();
    shape?.addDependent(this);
  }

  @override
  void update(int dirt) {
    if (dirt & ComponentDirt.worldTransform != 0 &&
        shape != null &&
        !shape.fillInWorld) {
      _shapeInverseWorld ??= Mat2D();
      Mat2D.invert(_shapeInverseWorld, shape.worldTransform);
    }
  }

  @override
  void isVisibleChanged(bool from, bool to) {
    // Redraw
    _shape?.addDirt(ComponentDirt.paint);
  }
  
  // -> editor-only
  @override
  bool validate() {
    return _shape != null && super.validate();
  }
  // <- editor-only
}
