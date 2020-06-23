import 'dart:math' as math;
import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/items/stage_handle.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_scale_transformer.dart';
import 'package:rive_editor/selectable_item.dart';

class StageScaleHandle extends StageHandle {
  final Vec2D direction;
  final Paint paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Paint hoverPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Paint headPaint = Paint();

  final Paint headHoverPaint = Paint()..color = const Color(0xFFFFFFFF);

  final Paint shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x26000000)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static const double headSize = 7;
  static const double handleLength = 29;
  static const double selectionThreshold = 10;
  static const double squaredSelectionThreshold =
      selectionThreshold * selectionThreshold;
  static const minScaleCorrection = 1 / Stage.minZoom;
  static const double halfSelectionThreshold = selectionThreshold / 2;
  StageScaleHandle({Color color, this.direction}) {
    headPaint.color = paint.color = color;
  }

  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(draw, order: 1002, inWorldSpace: false),
        StageDrawPass(drawShadow, order: 999, inWorldSpace: false),
      ];

  @override
  bool get isSelectable => false;

  @override
  bool get isHoverSelectable => isVisible;

  @override
  bool hitHiFi(Vec2D worldMouse) {
    var originWorld = renderTranslation;
    var tipWorld = Vec2D.add(Vec2D(), renderTranslation,
        Vec2D.scale(Vec2D(), computeAxis(), handleLength / stage.viewZoom));
    return math.sqrt(
            Vec2D.segmentSquaredDistance(originWorld, tipWorld, worldMouse)) <
        selectionThreshold / stage.viewZoom;
  }

  Vec2D computeAxis() {
    var value = Vec2D.transformMat2(Vec2D(), direction, renderTransform);
    Vec2D.normalize(value, value);
    return value;
  }

  @override
  void transformChanged() {
    
    var axisNormalized = computeAxis();
    var axis =
        Vec2D.scale(Vec2D(), axisNormalized, handleLength * minScaleCorrection);
    var orthogonal = Vec2D.scale(
        Vec2D(),
        Vec2D.fromValues(-axisNormalized[1], axisNormalized[0]),
        halfSelectionThreshold * minScaleCorrection);

    var origin = Mat2D.getTranslation(renderTransform, Vec2D());

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

  void _draw(Canvas canvas, Paint paint, Paint headPaint) {
    var screenPosition =
        Vec2D.transformMat2D(Vec2D(), renderTranslation, stage.viewTransform);

    var axis = Vec2D.scale(Vec2D(), computeAxis(), handleLength);

    canvas.save();

    canvas.translate(screenPosition[0].roundToDouble() - 0.5,
        screenPosition[1].roundToDouble() - 0.5);

    canvas.rotate(math.atan2(axis[0], -axis[1]));
    canvas.drawLine(Offset.zero, const Offset(0, -handleLength), paint);
    canvas.drawRect(
        Rect.fromCenter(
          center: const Offset(0, -handleLength),
          width: headSize,
          height: headSize,
        ),
        headPaint);
    canvas.restore();
  }

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) => _draw(
      canvas,
      selectionState.value != SelectionState.none ? hoverPaint : paint,
      selectionState.value != SelectionState.none ? headHoverPaint : headPaint);

  void drawShadow(Canvas canvas, StageDrawPass drawPass) =>
      _draw(canvas, shadowPaint, shadowPaint);

  @override
  List<StageTransformer> makeTransformers() {
    return [NodeScaleTransformer(
      lockAxis: direction, handle: this)];
  }
}
