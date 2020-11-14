import 'dart:ui';

import 'package:core/core.dart';
import 'package:core/id.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/clipping_shape_base.dart';
export 'package:rive_core/src/generated/shapes/clipping_shape_base.dart';

class ClippingShape extends ClippingShapeBase {
  final Path clippingPath = Path();
  final List<Shape> _shapes = [];
  PathFillType get fillType => PathFillType.values[fillRule];
  set fillType(PathFillType type) => fillRule = type.index;

  Node _source;
  Node get source => _source;
  set source(Node value) {
    if (_source == value) {
      return;
    }

    // -> editor-only

    // Handle when a shape is deleted. #1177
    _source?.cancelWhenRemoved(remove);
    value?.whenRemoved(remove);

    // <- editor-only

    _source = value;
    sourceId = value?.id;
  }

  // -> editor-only
  @override
  String get name => _source?.name;

  @override
  set name(String value) => _source?.name = value;

  @override
  Core eventDelegateFor(int propertyKey) {
    switch (propertyKey) {
      case ComponentBase.namePropertyKey:
        return _source;
      default:
        return this;
    }
  }
  // <- editor-only

  @override
  void fillRuleChanged(int from, int to) {
    // In the future, if clipOp can change at runtime (animation), we may want
    // the shapes that use this as a clipping source to make them depend on this
    // clipping shape so we can add dirt to them directly.
    parent?.addDirt(ComponentDirt.clip, recurse: true);

    addDirt(ComponentDirt.path);
  }

  @override
  void sourceIdChanged(Id from, Id to) {
    source = context?.resolve(to);
  }

  @override
  void onAddedDirty() {
    super.onAddedDirty();
    if (sourceId != null) {
      _source = context?.resolve(sourceId);
    }
  }

  @override
  void buildDependencies() {
    super.buildDependencies();
    _shapes.clear();
    _source?.forAll((component) {
      if (component is Shape) {
        _shapes.add(component);
        //component.addDependent(this);
        component.pathComposer.addDependent(this);
      }
      return true;
    });

    // make sure we rebuild the clipping path.
    addDirt(ComponentDirt.path);
  }

  @override
  void onRemoved() {
    super.onRemoved();
    _shapes.clear();
  }

  @override
  void update(int dirt) {
    if (dirt & (ComponentDirt.worldTransform | ComponentDirt.path) != 0 &&
        source != null) {
      // Build the clipping path as one of our dependent shapes changes or we
      // added a shape.
      clippingPath.reset();
      clippingPath.fillType = fillType;
      for (final shape in _shapes) {
        if (!shape.fillInWorld) {
          clippingPath.addPath(shape.fillPath, Offset.zero,
              matrix4: shape.worldTransform.mat4);
        } else {
          clippingPath.addPath(shape.fillPath, Offset.zero);
        }
      }
    }
  }

  @override
  void isVisibleChanged(bool from, bool to) {
    // Redraw
    _source?.addDirt(ComponentDirt.paint);
  }

  // -> editor-only
  @override
  bool validate() {
    return _source != null && super.validate();
  }
  // <- editor-only
}
