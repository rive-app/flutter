import 'dart:ui';

import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/transform_space.dart';

/// An abstraction to give a common interface to any component that can contain
/// fills and strokes.
abstract class ShapePaintContainer {
  final Set<Fill> fills = {};
  final Event fillsChanged = Event();

  @protected
  bool addFill(Fill fill) {
    if (fills.add(fill)) {
      fillsChanged.notify();
      return true;
    }
    return false;
  }

  @protected
  bool removeFill(Fill fill) {
    if (fills.remove(fill)) {
      fillsChanged.notify();
      return true;
    }
    return false;
  }

  /// Compute the bounds of this object in the requested transform space. This
  /// can be used by the color inspector to find the bounds of a shape or
  /// artboard to place the start/end at sensical locations.
  Rect computeBounds(TransformSpace space);

  /// These usually gets auto implemented as this mixin is meant to be added to
  /// a ComponentBase. This way the implementor doesn't need to cast
  /// ShapePaintContainer to ContainerComponent/Shape/Artboard/etc.
  bool addDirt(int value, {bool recurse = false});
  RiveFile get context;
  bool addDependent(Component dependent);
  void appendChild(Component child);
  Mat2D get worldTransform;
}
