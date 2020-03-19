import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';
export 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';

/// Generic ShapePaint that abstracts Stroke and Fill. Automatically hooks up
/// parent [Shape] to child [ShapePaintMutator]s.
abstract class ShapePaint extends ShapePaintBase {
  Paint _paint;
  Paint get paint => _paint;
  ShapePaintMutator _paintMutator;
  Shape _shape;

  ShapePaint() {
    _paint = makePaint();
  }

  ShapePaintMutator get paintMutator => _paintMutator;
  final Event paintMutatorChanged = Event();

  void _changeMutator(ShapePaintMutator mutator) {
    _paint = makePaint();
    _paintMutator = mutator;
    paintMutatorChanged?.notify();
  }

  /// Implementing classes are expected to override this to create a paint
  /// object. This gets called whenever the mutator is changed in order to not
  /// require each mutator to manually reset the paint to some canonical state.
  /// Instead, we simply blow out the old one and make a new one.
  @protected
  Paint makePaint();

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    if (child is ShapePaintMutator) {
      _changeMutator(child as ShapePaintMutator);
      _initMutator();
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    // Make sure to clean up any references so that they can be garbage
    // collected.
    if (child is ShapePaintMutator &&
        _paintMutator == child as ShapePaintMutator) {
      _changeMutator(null);
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

  void draw(Canvas canvas, PathComposer pathComposer);
}
