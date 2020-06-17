import 'dart:math' as math;
import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_translate_transformer.dart';
import 'package:rive_editor/selectable_item.dart';

abstract class TransformerMaker {
  List<StageTransformer> makeTransformers();
}

class StageTranslationHandle extends StageItem<void> with TransformerMaker {
  final Mat2D _transform = Mat2D();
  final Vec2D direction;
  final Paint paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  final Paint hoverPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 1;

  static const double handleLength = 100;
  static const double selectionThreshold = 10;
  static const double squaredSelectionThreshold =
      selectionThreshold * selectionThreshold;
  static const minScaleCorrection = 1 / Stage.minZoom;
  static const double halfSelectionThreshold = selectionThreshold / 2;
  StageTranslationHandle({Color color, this.direction}) {
    paint.color = color;
  }

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(this, order: 1000, inWorldSpace: false)];

  @override
  bool get isSelectable => false;

  @override
  bool get isHoverSelectable => isVisible;

  @override
  bool hitHiFi(Vec2D worldMouse) {
    var originWorld = translation;
    var tipWorld = Vec2D.add(Vec2D(), translation,
        Vec2D.scale(Vec2D(), computeAxis(), handleLength / stage.viewZoom));
    return math.sqrt(
            Vec2D.segmentSquaredDistance(originWorld, tipWorld, worldMouse)) <
        selectionThreshold / stage.viewZoom;
  }

  Vec2D computeAxis() {
    var value = Vec2D.transformMat2(Vec2D(), direction, _transform);
    Vec2D.normalize(value, value);
    return value;
  }

  Mat2D get transform => _transform;
  set transform(Mat2D transform) {
    if (Mat2D.areEqual(transform, _transform)) {
      return;
    }
    Mat2D.copy(_transform, transform);

    var axisNormalized = computeAxis();
    var axis =
        Vec2D.scale(Vec2D(), axisNormalized, handleLength * minScaleCorrection);
    var orthogonal = Vec2D.scale(
        Vec2D(),
        Vec2D.fromValues(-axisNormalized[1], axisNormalized[0]),
        halfSelectionThreshold * minScaleCorrection);

    var origin = Mat2D.getTranslation(_transform, Vec2D());

    var min = Vec2D.subtract(Vec2D(), origin, orthogonal);
    var max = Vec2D.add(Vec2D(), origin, orthogonal);
    aabb = AABB.fromPoints(
      [
        min,
        max,
        Vec2D.add(Vec2D(), min, axis),
        Vec2D.add(Vec2D(), max, axis),
      ],
    );
  }

  Vec2D get translation => Mat2D.getTranslation(_transform, Vec2D());

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    var screenPosition =
        Vec2D.transformMat2D(Vec2D(), translation, stage.viewTransform);

    var axis = Vec2D.scale(Vec2D(), computeAxis(), handleLength);

    canvas.drawLine(
      Offset(screenPosition[0], screenPosition[1]),
      Offset(screenPosition[0] + axis[0], screenPosition[1] + axis[1]),
      selectionState.value != SelectionState.none ? hoverPaint : paint,
    );
  }

  @override
  List<StageTransformer> makeTransformers() {
    return [NodeTranslateTransformer(lockAxis: computeAxis())];
  }
}
