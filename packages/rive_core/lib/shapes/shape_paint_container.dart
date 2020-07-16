import 'dart:ui';

import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/paint/stroke.dart';

/// An abstraction to give a common interface to any component that can contain
/// fills and strokes.
abstract class ShapePaintContainer {
  final Set<Fill> fills = {};
  // -> editor-only
  final Event fillsChanged = Event();
  // <- editor-only

  final Set<Stroke> strokes = {};
  // -> editor-only
  final Event strokesChanged = Event();
  // <- editor-only

  /// Called whenever a new paint mutator is added/removed from the shape paints
  /// (for example a linear gradient is added to a stroke).
  void onPaintMutatorChanged(ShapePaintMutator mutator);

  /// Called when a fill is added or removed.
  @protected
  void onFillsChanged();

  /// Called when a stroke is added or remoevd.
  @protected
  void onStrokesChanged();

  @protected
  bool addFill(Fill fill) {
    if (fills.add(fill)) {
      // -> editor-only
      fillsChanged.notify();
      // <- editor-only
      onFillsChanged();
      return true;
    }
    return false;
  }

  @protected
  bool removeFill(Fill fill) {
    if (fills.remove(fill)) {
      // -> editor-only
      fillsChanged.notify();
      // <- editor-only
      onFillsChanged();
      return true;
    }
    return false;
  }

  @protected
  bool addStroke(Stroke stroke) {
    if (strokes.add(stroke)) {
      // -> editor-only
      strokesChanged.notify();
      // <- editor-only
      onStrokesChanged();
      return true;
    }
    return false;
  }

  @protected
  bool removeStroke(Stroke stroke) {
    if (strokes.remove(stroke)) {
      // -> editor-only
      strokesChanged.notify();
      // <- editor-only
      onStrokesChanged();
      return true;
    }
    return false;
  }

  /// Compute the bounds of this object in the requested transform space. This
  /// can be used by the color inspector to find the bounds of a shape or
  /// artboard to place the start/end at sensical locations.
  AABB get worldBounds;
  AABB get localBounds;

  /// These usually gets auto implemented as this mixin is meant to be added to
  /// a ComponentBase. This way the implementor doesn't need to cast
  /// ShapePaintContainer to ContainerComponent/Shape/Artboard/etc.
  bool addDirt(int value, {bool recurse = false});
  // -> editor-only
  RiveFile get context;
  // <- editor-only
  bool addDependent(Component dependent);
  void appendChild(Component child);
  Mat2D get worldTransform;
  Vec2D get worldTranslation;

  // -> editor-only
  /// Create a new color fill and add it to this shape.
  Fill createFill([Color color]) {
    assert(context != null);

    Fill fill;
    context.batchAdd(() {
      fill = Fill()..name = 'Fill ${fills.length + 1}';
      final solidColor = SolidColor();
      if (color != null) {
        solidColor.color = color;
      }

      context.addObject(fill);
      context.addObject(solidColor);

      fill.appendChild(solidColor);
      appendChild(fill);
    });
    return fill;
  }

  /// Creates a default linear gradient fill
  Fill createGradientFill() {
    assert(context != null);

    Fill fill;
    context.batchAdd(() {
      fill = Fill()..name = 'Fill ${fills.length + 1}';

      final gradient = LinearGradient();

      // Get the gradient bounds
      var rect = Rect.fromLTRB(
          localBounds[0], localBounds[1], localBounds[2], localBounds[3]);
      gradient
        ..startX = rect.left
        ..startY = rect.centerLeft.dy
        ..endX = rect.right
        ..endY = rect.centerLeft.dy;

      // Add the two stops
      final gradientStopA = GradientStop()
        ..color = const Color(0xFF000000)
        ..position = 0;
      final gradientStopB = GradientStop()
        ..color = const Color(0x00000000)
        ..position = 1;

      context.addObject(fill);
      context.addObject(gradient);
      context.addObject(gradientStopA);
      context.addObject(gradientStopB);

      gradient.appendChild(gradientStopA);
      gradient.appendChild(gradientStopB);

      fill.appendChild(gradient);
      appendChild(fill);
    });
    return fill;
  }

  /// Create a new color stroke and add it to this shape.
  Stroke createStroke(Color color) {
    assert(context != null);
    assert(color != null);
    Stroke stroke;
    context.batchAdd(() {
      stroke = Stroke()..name = 'Stroke ${strokes.length + 1}';
      var solidColor = SolidColor()..color = color;

      context.addObject(stroke);
      context.addObject(solidColor);

      stroke.appendChild(solidColor);
      appendChild(stroke);
    });
    return stroke;
  }
  // <- editor-only
}
