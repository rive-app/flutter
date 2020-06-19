import 'package:rive/rive_core/component.dart';
import 'package:rive/rive_core/event.dart';
import 'package:rive/rive_core/math/aabb.dart';
import 'package:rive/rive_core/math/mat2d.dart';
import 'package:rive/rive_core/math/vec2d.dart';
import 'package:rive/rive_core/shapes/paint/fill.dart';
import 'package:meta/meta.dart';
import 'package:rive/rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive/rive_core/shapes/paint/stroke.dart';

abstract class ShapePaintContainer {
  final Set<Fill> fills = {};
  final Event fillsChanged = Event();
  final Set<Stroke> strokes = {};
  final Event strokesChanged = Event();
  void onPaintMutatorChanged(ShapePaintMutator mutator);
  @protected
  void onFillsChanged();
  @protected
  void onStrokesChanged();
  @protected
  bool addFill(Fill fill) {
    if (fills.add(fill)) {
      fillsChanged.notify();
      onFillsChanged();
      return true;
    }
    return false;
  }

  @protected
  bool removeFill(Fill fill) {
    if (fills.remove(fill)) {
      fillsChanged.notify();
      onFillsChanged();
      return true;
    }
    return false;
  }

  @protected
  bool addStroke(Stroke stroke) {
    if (strokes.add(stroke)) {
      strokesChanged.notify();
      onStrokesChanged();
      return true;
    }
    return false;
  }

  @protected
  bool removeStroke(Stroke stroke) {
    if (strokes.remove(stroke)) {
      strokesChanged.notify();
      onStrokesChanged();
      return true;
    }
    return false;
  }

  AABB get worldBounds;
  AABB get localBounds;
  bool addDirt(int value, {bool recurse = false});
  bool addDependent(Component dependent);
  void appendChild(Component child);
  Mat2D get worldTransform;
  Vec2D get worldTranslation;
}
