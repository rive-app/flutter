import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_editor/rive/stage/items/stage_gradient_stop.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

abstract class StageGradientInterface {
  final Set<StageGradientStop> stops = {};

  void addStop(StageGradientStop stop) {
    if (stops.add(stop)) {
      stopsChanged();
    }
  }

  void removeStop(StageGradientStop stop) {
    if (stops.remove(stop)) {
      stopsChanged();
    }
  }

  @protected
  void stopsChanged();

  core.LinearGradient get component;
}

class StageLinearGradient extends StageItem<core.LinearGradient>
    with StageGradientInterface
    implements GradientDelegate {
  static Paint border = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x40000000);

  static Paint line = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF);

  @override
  bool get isSelectable => false;

  @override
  bool get isAutomatic => false;

  @override
  int get drawOrder => 2;

  StageShape get stageShape =>
      (component.shapePaintContainer as Component).stageItem as StageShape;

  @override
  bool initialize(core.LinearGradient object) {
    if (!super.initialize(object)) {
      return false;
    }
    _update();
    return true;
  }

  Offset _startOffset;
  Offset _endOffset;

  Vec2D _start;
  Vec2D _end;

  void _update() {
    // We want the start and end in world transform space, regardless of how the
    // shape paints.
    var world = Mat2D.translate(
        Mat2D(),
        component.shapePaintContainer.worldTransform,
        component.artboard.originWorld);

    _start = Vec2D.transformMat2D(Vec2D(), component.start, world);
    _end = Vec2D.transformMat2D(Vec2D(), component.end, world);

    // Compute world transform of start/end points expand by our stroke
    // dimensions (make sure the bounding box is at least that wide/high).
    aabb = AABB.fromPoints([_start, _end], expand: 2);
    _startOffset = Offset(_start[0], _start[1]);
    _endOffset = Offset(_end[0], _end[1]);
  }

  @override
  void stopsChanged() {
    // We're guaranteed that the bounds will already have updated by now so we
    // can safely just position the stops.
    var diff = Vec2D.subtract(Vec2D(), _end, _start);
    var gradientStops = component.gradientStops;

    // This only works if we have at least two gradient stops. When we implement
    // deleting the stops, we need to make sure to not allow deleting the final
    // last two stops (which is common in most editors).
    if (gradientStops.length < 2) {
      return;
    }

    var first = component.gradientStops.first;
    var last = component.gradientStops.last;

    for (final stop in stops) {
      // Place first and last at the start and end positions respectively
      // (regardless of what their gradient position actually is within the
      // range). Note that stops are not ordered but component.gradientStops
      // are.
      if (stop.component == first) {
        stop.update(_start);
      } else if (stop.component == last) {
        stop.update(_end);
      } else {
        var pos = Vec2D.scale(Vec2D(), diff, stop.component.position);
        Vec2D.add(pos, _start, pos);
        stop.update(pos);
      }
    }
  }

  @override
  void boundsChanged() => _update();

  @override
  void draw(Canvas canvas) {
    border.strokeWidth = 3 / stage.viewZoom;
    line.strokeWidth = 1 / stage.viewZoom;

    canvas.drawLine(_startOffset, _endOffset, border);
    canvas.drawLine(_startOffset, _endOffset, line);
  }
}
