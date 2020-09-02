import 'package:flutter/material.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/shapes/paint/stroke_effect.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/src/generated/shapes/paint/stroke_base.dart';
export 'package:rive_core/src/generated/shapes/paint/stroke_base.dart';

/// A stroke Shape painter.
class Stroke extends StrokeBase {
  StrokeEffect _effect;
  StrokeEffect get effect => _effect;

  // -> editor-only
  final Event effectChanged = Event();
  // <- editor-only

  // Should be @internal when supported.
  // ignore: use_setters_to_change_properties
  void addStrokeEffect(StrokeEffect effect) {
    _effect = effect;
    // -> editor-only
    effectChanged.notify();
    // <- editor-only
  }

  void removeStrokeEffect(StrokeEffect effect) {
    if (effect == _effect) {
      _effect = null;
      // -> editor-only
      effectChanged.notify();
      // <- editor-only
    }
  }

  @override
  Paint makePaint() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin
    ..strokeWidth = thickness;

  // -> editor-only
  @override
  String get timelineParentGroup => 'strokes';
  // <- editor-only

  StrokeCap get strokeCap => StrokeCap.values[cap];
  set strokeCap(StrokeCap value) => cap = value.index;

  StrokeJoin get strokeJoin => StrokeJoin.values[join];
  set strokeJoin(StrokeJoin value) => join = value.index;

  @override
  void capChanged(int from, int to) {
    paint.strokeCap = StrokeCap.values[to];
    parent?.addDirt(ComponentDirt.paint);
  }

  @override
  void joinChanged(int from, int to) {
    paint.strokeJoin = StrokeJoin.values[to];
    parent?.addDirt(ComponentDirt.paint);
  }

  @override
  void thicknessChanged(double from, double to) {
    paint.strokeWidth = to;
    parent?.addDirt(ComponentDirt.paint);
  }

  @override
  void transformAffectsStrokeChanged(bool from, bool to) {
    var parentShape = parent;
    if (parentShape is Shape) {
      parentShape.paintChanged();
    }
  }

  @override
  void update(int dirt) {
    // Intentionally empty, fill doesn't update.
    // Because Fill never adds dependencies, it'll also never get called.
  }

  @override
  void onAdded() {
    super.onAdded();
    if (parent is ShapePaintContainer) {
      (parent as ShapePaintContainer).addStroke(this);
    }
  }

  void invalidateEffects() {
    _effect?.invalidateEffect();
  }

  // -> editor-only
  @override
  bool validate() => super.validate() && parent is ShapePaintContainer;
  // <- editor-only

  @override
  void draw(Canvas canvas, Path path) {
    if (!isVisible) {
      return;
    }

    canvas.drawPath(_effect?.effectPath(path) ?? path, paint);
  }
}
