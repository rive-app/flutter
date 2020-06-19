import 'dart:math';
import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/items/stage_translation_handle.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/node_rotate_transformer.dart';
import 'package:rive_editor/selectable_item.dart';

class StageRotationHandle extends StageItem<void> with TransformerMaker {
  final Mat2D _transform = Mat2D();
  final bool showAxis;
  final Paint paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFFF1BE)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Paint slicePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x80FFF1BE);

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

  static const double radius = 60;
  static const double selectionThreshold = 10;
  static const double centerRadius = 5;
  static const double hitMin = radius - selectionThreshold;
  static const double hitMax = radius + selectionThreshold;
  static const double squaredSelectionThreshold =
      selectionThreshold * selectionThreshold;
  static const minScaleCorrection = 1 / Stage.minZoom;
  static const double halfSelectionThreshold = selectionThreshold / 2;

  StageRotationHandle({this.showAxis = false});

  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(draw, order: 1000, inWorldSpace: false),
        StageDrawPass(drawShadow, order: 999, inWorldSpace: false),
      ];

  @override
  bool get isSelectable => false;

  @override
  bool get isHoverSelectable => isVisible;

  @override
  bool hitHiFi(Vec2D worldMouse) {
    var hitRadiusMax = hitMax / stage.viewZoom;
    var hitRadiusMin = hitMin / stage.viewZoom;
    var distanceSquared = Vec2D.squaredDistance(worldMouse, translation);
    return distanceSquared < hitRadiusMax * hitRadiusMax &&
        distanceSquared > hitRadiusMin * hitRadiusMin;
  }

  Vec2D computeAxis() {
    var value =
        Vec2D.transformMat2(Vec2D(), Vec2D.fromValues(1, 0), _transform);
    Vec2D.normalize(value, value);
    return value;
  }

  Mat2D get transform => _transform;
  set transform(Mat2D transform) {
    if (Mat2D.areEqual(transform, _transform)) {
      return;
    }
    Mat2D.copy(_transform, transform);
    var origin = Mat2D.getTranslation(_transform, Vec2D());

    var scaledRadius = radius * minScaleCorrection;
    var r = Vec2D.fromValues(scaledRadius, scaledRadius);
    aabb = AABB.fromMinMax(
      Vec2D.subtract(Vec2D(), origin, r),
      Vec2D.add(Vec2D(), origin, r),
    );
  }

  Vec2D get translation => Mat2D.getTranslation(_transform, Vec2D());

  void _draw(Canvas canvas, Paint paint) {
    var screenPosition =
        Vec2D.transformMat2D(Vec2D(), translation, stage.viewTransform);

    canvas.save();

    canvas.translate(screenPosition[0].roundToDouble() - 0.5,
        screenPosition[1].roundToDouble() - 0.5);

    canvas.drawCircle(Offset.zero, radius, paint);
    canvas.restore();
  }

  double _sliceStart, _sliceEnd;

  void showSlice(double start, double end) {
    _sliceStart = start;
    _sliceEnd = end;
    stage.markNeedsRedraw();
  }

  void hideSlice() {
    _sliceStart = _sliceEnd = null;
  }

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    var slicePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x80FFF1BE);
    if (_sliceStart != null) {
      var screenPosition =
          Vec2D.transformMat2D(Vec2D(), translation, stage.viewTransform);

      canvas.save();

      canvas.translate(screenPosition[0].roundToDouble() - 0.5,
          screenPosition[1].roundToDouble() - 0.5);

      // Cut out the center.
      var centerCut = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromCircle(center: Offset.zero, radius: radius + 10))
        ..addOval(
          Rect.fromCircle(
            center: Offset.zero,
            radius: centerRadius,
          ),
        );
      canvas.clipPath(centerCut);

      // canvas.drawCircle(Offset.zero, radius, paint);
      var rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      var sweep = _sliceEnd - _sliceStart;

      if (sweep < 0) {
        var s = _sliceStart;
        _sliceStart = _sliceEnd;
        _sliceEnd = s;
        sweep = _sliceEnd - _sliceStart;
      }

      var loops = (sweep / (pi * 2)).abs().floor();
      for (var i = 0; i < loops; i++) {
        canvas.drawOval(rect, slicePaint);
      }

      canvas.drawArc(rect, _sliceStart, (_sliceEnd - _sliceStart) % (pi * 2),
          true, slicePaint);
      canvas.restore();
    }
    _draw(canvas,
        selectionState.value != SelectionState.none ? hoverPaint : paint);
  }

  void drawShadow(Canvas canvas, StageDrawPass drawPass) =>
      _draw(canvas, shadowPaint);

  @override
  List<StageTransformer> makeTransformers() {
    return [NodeRotateTransformer(handle: this)];
  }
}
