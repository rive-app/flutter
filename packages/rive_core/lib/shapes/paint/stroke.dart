import 'package:flutter/material.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/paint/stroke_base.dart';
export 'package:rive_core/src/generated/shapes/paint/stroke_base.dart';

/// A stroke Shape painter.
class Stroke extends StrokeBase {
  @override
  Paint makePaint() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin
    ..strokeWidth = thickness;

  StrokeCap get strokeCap => StrokeCap.values[cap];
  set strokeCap(StrokeCap value) => cap = value.index;

  StrokeJoin get strokeJoin => StrokeJoin.values[join];
  set strokeJoin(StrokeJoin value) => join = value.index;

  @override
  void capChanged(int from, int to) {
    super.capChanged(from, to);
    paint.strokeCap = StrokeCap.values[to];
    parent?.addDirt(ComponentDirt.paint);
  }

  @override
  void joinChanged(int from, int to) {
    super.joinChanged(from, to);
    paint.strokeJoin = StrokeJoin.values[to];
    parent?.addDirt(ComponentDirt.paint);
  }

  @override
  void thicknessChanged(double from, double to) {
    super.thicknessChanged(from, to);
    paint.strokeWidth = to;
    parent?.addDirt(ComponentDirt.paint);
  }

  @override
  void transformAffectsStrokeChanged(bool from, bool to) {
    super.transformAffectsStrokeChanged(from, to);
    var parentShape = parent;
    if (parentShape is Shape) {
      parentShape.transformAffectsStrokeChanged();
    }
  }

  @override
  void update(int dirt) {
    // Intentionally empty, fill doesn't update.
    // Because Fill never adds dependencies, it'll also never get called.
  }

  @override
  void draw(Canvas canvas, Path path) {
    if (!isVisible) {
      return;
    }
    
    canvas.drawPath(path, paint);
  }
}
