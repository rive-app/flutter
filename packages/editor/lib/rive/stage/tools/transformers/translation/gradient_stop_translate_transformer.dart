import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/math/segment2d.dart';

import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageItem]'s with underlying [GradientStop]
/// components.
class GradientStopTranslateTransformer extends StageTransformer {
  // We can only transform one stop at a time.
  GradientStop _stop;

  @override
  void advance(DragTransformDetails details) {
    var gradient = _stop.parent as LinearGradient;
    var shapeWorld = gradient.shapePaintContainer.worldTransform;
    Mat2D shapeWorldInverse = Mat2D();
    if (!Mat2D.invert(shapeWorldInverse, shapeWorld)) {
      // If the inversion fails (0 scale?) then don't allow moving the stop.
      return;
    }

    var delta = Vec2D.transformMat2(
        Vec2D(), details.artboardWorld.delta, shapeWorldInverse);

    var index = gradient.gradientStops.indexOf(_stop);

    // First and last gradient stops move the start/end.
    if (index == 0) {
      gradient.startX += delta[0];
      gradient.startY += delta[1];
    } else if (index == gradient.gradientStops.length - 1) {
      gradient.endX += delta[0];
      gradient.endY += delta[1];
    } else {
      // Need to project to start/end.
      // compute translation of this point.

      var diff = Vec2D.subtract(Vec2D(), gradient.end, gradient.start);
      var translation = Vec2D.add(
          Vec2D(), gradient.start, Vec2D.scale(Vec2D(), diff, _stop.position));
      Vec2D.add(translation, translation, delta);

      // Now project it to the line
      var segment = Segment2D(gradient.start, gradient.end);
      var result = segment.projectPoint(translation);
      _stop.position = result.t;
    }
  }

  @override
  void complete() {}

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    _stop = items
        .firstWhere((item) => item.component is GradientStop,
            orElse: () => null)
        ?.component as GradientStop;
    if (_stop != null) {
      // Don't let anyone else keep transforming.
      items.clear();
      return true;
    }
    return false;
  }
}
