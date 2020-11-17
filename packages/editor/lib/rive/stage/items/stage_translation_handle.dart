import 'dart:math' as math;
import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/items/stage_handle.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/artboard_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/joint_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_translate_transformer.dart';
import 'package:rive_editor/selectable_item.dart';

class StageTranslationHandle extends StageHandle {
  @override
  final int transformType;
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

  final Paint shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x26000000)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Path arrow = Path()
    ..moveTo(0, 0)
    ..lineTo(0, -handleLength)
    ..moveTo(0 + arrowSize, -handleLength + arrowSize)
    ..lineTo(0, 0 - handleLength)
    ..lineTo(0 - arrowSize, -handleLength + arrowSize);
  static const double arrowSize = 5;
  static const double handleLength = 100;
  static const double selectionThreshold = 10;
  static const double squaredSelectionThreshold =
      selectionThreshold * selectionThreshold;
  static const minScaleCorrection = 1 / Stage.minZoom;
  static const double halfSelectionThreshold = selectionThreshold / 2;
  StageTranslationHandle({Color color, this.direction, this.transformType}) {
    paint.color = color;
  }

  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(draw, order: 1001, inWorldSpace: false),
        StageDrawPass(drawShadow, order: 999, inWorldSpace: false),
      ];

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

  void _draw(Canvas canvas, Paint paint) {
    var screenPosition =
        Vec2D.transformMat2D(Vec2D(), renderTranslation, stage.viewTransform);

    var axis = Vec2D.scale(Vec2D(), computeAxis(), handleLength);

    canvas.save();

    canvas.translate(screenPosition[0].roundToDouble() - 0.5,
        screenPosition[1].roundToDouble() - 0.5);

    canvas.rotate(math.atan2(axis[0], -axis[1]));
    canvas.drawPath(
      arrow,
      paint,
    );
    canvas.restore();
  }

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) => _draw(
      canvas, selectionState.value != SelectionState.none ? hoverPaint : paint);

  void drawShadow(Canvas canvas, StageDrawPass drawPass) =>
      _draw(canvas, shadowPaint);

  @override
  List<StageTransformer> makeTransformers() {
    stage.snapper.lockAxis = computeAxis();
    return [
      NodeTranslateTransformer(),
      JointTranslateTransformer(),
      ArtboardTranslateTransformer(),
    ];
  }
}
