import 'dart:ui';

import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';
export 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';

/// Generic ShapePaint that abstracts Stroke and Fill. Automatically hooks up
/// parent [Shape] to child [ShapePaintMutator]s.
abstract class ShapePaint extends ShapePaintBase {
  final Paint paint = Paint();
  ShapePaintMutator _paintMutator;
  Shape _shape;

  ShapePaintMutator get paintMutator => _paintMutator;

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    if (child is ShapePaintMutator) {
      _paintMutator = child as ShapePaintMutator;
      _initMutator();
    }
  }

  @override
  void childRemoved(Component child) {
    super.childAdded(child);
    // Make sure to clean up any references so that they can be garbage
    // collected.
    if (child is ShapePaintMutator &&
        _paintMutator == child as ShapePaintMutator) {
      _paintMutator = null;
    }
  }

  @override
  void parentChanged(ContainerComponent from, ContainerComponent to) {
    super.parentChanged(from, to);
    if (parent is Shape) {
      _shape = parent as Shape;
      _initMutator();
    } else {
      // Important to clear old references so they can be garbage collected.
      _shape = null;
    }
  }

  void _initMutator() {
    if (_shape != null && _paintMutator != null) {
      _paintMutator.initializePaintMutator(_shape, paint);
    }
  }
}
