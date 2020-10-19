import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';
export 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';

/// Generic ShapePaint that abstracts Stroke and Fill. Automatically hooks up
/// parent [Shape] to child [ShapePaintMutator]s.
abstract class ShapePaint extends ShapePaintBase {
  Paint _paint;
  Paint get paint => _paint;
  ShapePaintMutator _paintMutator;
  ShapePaintContainer _shapePaintContainer;
  ShapePaintContainer get shapePaintContainer => _shapePaintContainer;

  ShapePaint() {
    _paint = makePaint();
  }

  BlendMode get blendMode => _paint.blendMode;
  set blendMode(BlendMode value) => _paint.blendMode = value;

  double get renderOpacity => _paintMutator.renderOpacity;
  set renderOpacity(double value) => _paintMutator.renderOpacity = value;

  ShapePaintMutator get paintMutator => _paintMutator;
  // -> editor-only
  final Event paintMutatorChanged = Event();

  @override
  Component get timelineParent => _shapePaintContainer as Component;
  // <- editor-only

  void _changeMutator(ShapePaintMutator mutator) {
    _paint = makePaint();
    _paintMutator = mutator;
    // -> editor-only
    paintMutatorChanged?.notify();
    // <- editor-only
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

  // -> editor-only
  @override
  void onAdded() {
    super.onAdded();

    // Shape paints change out of order only during editing, we don't need to
    // re-build the entire list every time one of these is added at runtime.
    _shapePaintContainer?.updateShapePaints();

    // ShapePaint has been added and is clean (all artboards and ancestors of
    // the current hierarchy's components have resolved). This is a good
    // opportunity to self-heal when paint mutators are missing.
    if (_paintMutator == null) {
      var solid = SolidColor()..colorValue = 0xFF000000;
      context?.batchAdd(() {
        context.addObject(solid);
        appendChild(solid);
      });
      context.objectPatched(this);
    }
  }

  @override
  void onRemoved() {
    super.onRemoved();
    _shapePaintContainer?.updateShapePaints();
  }

  @override
  bool validate() {
    if (!super.validate() || parent is! ShapePaintContainer) {
      return false;
    }

    // Shape paints should contain exactly one mutator.
    var paintMutators = children.whereType<ShapePaintMutator>();
    if (paintMutators.isEmpty) {
      // No mutator, this paint is invalid, get rid of it.
      return false;
    }

    // More than one mutator, we could also get rid of the paint object, but we
    // try to place nice and heal the file by keeping only the last mutator and
    // wiping out the older ones.
    if (paintMutators.length > 1) {
      var removeList = paintMutators.toList();
      for (int i = 0; i < removeList.length - 1; i++) {
        var component = removeList[i] as Component;
        if (component is ContainerComponent) {
          component.removeRecursive();
        } else {
          component.remove();
        }
      }
    }
    return true;
  }
  // <- editor-only

  @override
  void isVisibleChanged(bool from, bool to) {
    _shapePaintContainer?.addDirt(ComponentDirt.paint);
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
    if (parent is ShapePaintContainer) {
      _shapePaintContainer = parent as ShapePaintContainer;
      _initMutator();
    } else {
      // Important to clear old references so they can be garbage collected.
      _shapePaintContainer = null;
    }
  }

  void _initMutator() {
    if (_shapePaintContainer != null && _paintMutator != null) {
      _paintMutator.initializePaintMutator(_shapePaintContainer, paint);
    }
  }

  void draw(Canvas canvas, Path path);
}
