import 'dart:ui' as ui;

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/src/generated/shapes/paint/linear_gradient_base.dart';
export 'package:rive_core/src/generated/shapes/paint/linear_gradient_base.dart';

/// A core linear gradient. Can be added as a child to a [Shape]'s [Fill] or
/// [Stroke] to paint that Fill or Stroke with a gradient. This is the
/// foundation for the RadialGradient which is very similar but also has a
/// radius value.
class LinearGradient extends LinearGradientBase with ShapePaintMutator {
  /// Stored list of core gradient stops are in the hierarchy as children of
  /// this container.
  final List<GradientStop> gradientStops = [];

  /// Event triggered whenever a stops property changes.
  final Event stopsChanged = Event();

  static const int _worldSpace = 1 << 0;
  static const int _shapeSpace = 1 << 1;

  Vec2D get start => Vec2D.fromValues(startX, startY);
  Vec2D get end => Vec2D.fromValues(endX, endY);

  ui.Offset get startOffset => ui.Offset(startX, startY);
  ui.Offset get endOffset => ui.Offset(endX, endY);

  /// Tracks the spaces this gradient paints in. Because Shapes can have
  /// multiple paints and paint options, the gradient may need to paint in
  /// multiple spaces at the same time which is why we track this as a bit
  /// field. It also optimizes the update process such that we only build the
  /// transform spaces we want.
  int _transformSpace = 0;
  bool get paintsInWorldSpace => _transformSpace & _worldSpace != 0;
  bool get paintsInShapeSpace => _transformSpace & _shapeSpace != 0;

  void _changeTransformFlag(bool add, int flag) {
    var transformSpace = _transformSpace;
    if (add) {
      transformSpace |= flag;
    } else {
      transformSpace &= ~flag;
    }
    if (_transformSpace != transformSpace) {
      _transformSpace = transformSpace;
      addDirt(ComponentDirt.gradient);
    }
  }

  set paintsInWorldSpace(bool value) =>
      _changeTransformFlag(value, _worldSpace);

  set paintsInShapeSpace(bool value) =>
      _changeTransformFlag(value, _shapeSpace);

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    if (child is GradientStop && !gradientStops.contains(child)) {
      gradientStops.add(child);
      stopsChanged.notify();
      markStopsDirty();
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    if (child is GradientStop && gradientStops.contains(child)) {
      gradientStops.remove(child);
      stopsChanged.notify();
      markStopsDirty();
    }
  }

  /// Mark the gradient stops as changed. This will re-sort the stops and
  /// rebuild the necessary gradients in the next update cycle.
  void markStopsDirty() =>
      addDirt(ComponentDirt.stops | ComponentDirt.gradient);

  /// Mark the gradient as needing to be rebuilt. This is a more efficient
  /// version of markStopsDirty as it won't re-sort the stops.
  void markGradientDirty() => addDirt(ComponentDirt.gradient);

  @override
  void update(int dirt) {
    // Do the stops need to be re-ordered?
    if (dirt & ComponentDirt.stops != 0) {
      gradientStops.sort((a, b) => a.position.compareTo(b.position));
    }

    // Check if either of the gradients need to be rebuilt.
    var gradientDirty = dirt & ComponentDirt.gradient != 0;

    bool buildWorldSpaceGradient = paintsInWorldSpace &&
        (gradientDirty || (dirt & ComponentDirt.worldTransform) != 0);
    bool buildShapeSpaceGradient = paintsInShapeSpace && gradientDirty;

    if (buildWorldSpaceGradient || buildShapeSpaceGradient) {
      // If either of our gradients update, build up the color and positions
      // lists as we need them for both.
      var colors = <ui.Color>[];
      var colorPositions = <double>[];
      for (final stop in gradientStops) {
        colors.add(stop.color);
        colorPositions.add(stop.position);
      }
      // Chek if we need to update the world space gradient.
      if (buildWorldSpaceGradient) {
        // Get the start and end of the gradient in world coordinates (world
        // transform of the shape).
        var world = shape.worldTransform;
        var worldStart = Vec2D.transformMat2D(Vec2D(), start, world);
        var worldEnd = Vec2D.transformMat2D(Vec2D(), end, world);
        paint.shader = makeGradient(ui.Offset(worldStart[0], worldStart[1]),
            ui.Offset(worldEnd[0], worldEnd[1]), colors, colorPositions);
      }
      if (buildShapeSpaceGradient) {
        paint.shader =
            makeGradient(startOffset, endOffset, colors, colorPositions);
      }
    }
  }

  @protected
  ui.Gradient makeGradient(ui.Offset start, ui.Offset end,
          List<ui.Color> colors, List<double> colorPositions) =>
      ui.Gradient.linear(start, end, colors, colorPositions);
}
