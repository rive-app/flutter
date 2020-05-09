import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

/// Draws the interpolation preview and allows interacting/changing parameters
/// (such as cubic).
class InterpolationPreview extends StatelessWidget {
  static const double padding = 20;

  final InterpolationViewModel interpolation;
  final HashSet<KeyFrame> selection;
  final KeyFrameManager manager;
  final AnimationTimeManager timeManager;

  const InterpolationPreview({
    @required this.interpolation,
    @required this.selection,
    @required this.manager,
    @required this.timeManager,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ValueStreamBuilder<double>(
        stream: timeManager.currentTime,
        builder: (context, snapshot) {
          double normalizedTime = -1;
          if (selection.length == 1) {
            var key = selection.first;
            var keyedProperty = key.keyedProperty;
            var next = keyedProperty.after(key);
            if (next != null) {
              normalizedTime =
                  (snapshot.data - key.frame) / (next.frame - key.frame);
            }
          }
          switch (interpolation.type) {
            case KeyFrameInterpolation.hold:
              return _HoldPreviewRenderer(
                theme: RiveTheme.of(context),
                normalizedTime: normalizedTime,
              );
            case KeyFrameInterpolation.linear:
              return _LinearPreviewRenderer(
                theme: RiveTheme.of(context),
                normalizedTime: normalizedTime,
              );
              break;
            case KeyFrameInterpolation.cubic:
              var commonInterpolator = interpolation.interpolator;
              if (commonInterpolator is CubicInterpolator) {
                return _CubicPreviewRenderer(
                  theme: RiveTheme.of(context),
                  normalizedTime: normalizedTime,
                  controlIn:
                      Offset(commonInterpolator.x1, commonInterpolator.y1),
                  controlOut:
                      Offset(commonInterpolator.x2, commonInterpolator.y2),
                );
              }
              // I HATE THIS!
              // https://media.giphy.com/media/lWnWVVvNLL9hC/giphy.gif
              continue empty;
            empty:
            default:
              return _EmptyPreviewRenderer(
                theme: RiveTheme.of(context),
                normalizedTime: normalizedTime,
              );
          }
        },
      ),
    );
  }
}

class _HoldPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;

  const _HoldPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _HoldPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime;

  @override
  void updateRenderObject(
      BuildContext context, _HoldPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime;
  }
}

abstract class _InterpolationRenderBox extends RenderBox {
  double _normalizedTime = 0;
  double get normalizedTime => _normalizedTime;
  set normalizedTime(double value) {
    if (_normalizedTime == value) {
      return;
    }
    _normalizedTime = value;
    markNeedsPaint();
    return;
  }

  final Paint timePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final Paint interpolationPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final Paint separatorPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  final Paint background = Paint();

  RiveThemeData _theme;
  RiveThemeData get theme => _theme;
  set theme(RiveThemeData value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    interpolationPaint.color = value.colors.interpolationPreviewLine;
    separatorPaint.color = value.colors.interpolationPreviewSeparator;
    background.color = value.colors.interpolationCurveBackground;
    timePaint.color = value.colors.key;
    onThemeChanged();
    markNeedsPaint();
  }

  void onThemeChanged() {}

  double get renderPadding => InterpolationPreview.padding + 0.5;
  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
        background);
    canvas.drawLine(Offset(0, renderPadding), Offset(size.width, renderPadding),
        separatorPaint);
    canvas.drawLine(Offset(0, size.height - renderPadding),
        Offset(size.width, size.height - renderPadding), separatorPaint);

    paintInterpolation(canvas);

    if (_normalizedTime >= 0 && _normalizedTime <= 1) {
      var x = (_normalizedTime * size.width).round() + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), timePaint);
    }

    canvas.restore();
  }

  void paintInterpolation(Canvas canvas);
}

class _HoldPreviewRenderBox extends _InterpolationRenderBox {
  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {
    canvas.drawLine(Offset(0, size.height - renderPadding),
        Offset(size.width, size.height - renderPadding), interpolationPaint);
    canvas.drawLine(Offset(size.width - 0.5, size.height - renderPadding - 0.5),
        Offset(size.width - 0.5, renderPadding), interpolationPaint);
  }
}

class _LinearPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;

  const _LinearPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _LinearPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime;

  @override
  void updateRenderObject(
      BuildContext context, _LinearPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime;
  }
}

class _LinearPreviewRenderBox extends _InterpolationRenderBox {
  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {
    canvas.drawLine(Offset(0, size.height - renderPadding),
        Offset(size.width, renderPadding), interpolationPaint);
  }
}

class _CubicPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;
  final Offset controlIn;
  final Offset controlOut;

  const _CubicPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
    @required this.controlIn,
    @required this.controlOut,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _CubicPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime
        ..controlIn = controlIn
        ..controlOut = controlOut;

  @override
  void updateRenderObject(
      BuildContext context, _CubicPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime
      ..controlIn = controlIn
      ..controlOut = controlOut;
  }
}

class _CubicPreviewRenderBox extends _InterpolationRenderBox {
  Offset _renderIn;
  Offset _renderOut;

  final Paint controlLine = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final Path cubic = Path();
  Offset _controlIn;
  Offset get controlIn => _controlIn;
  set controlIn(Offset value) {
    if (value == _controlIn) {
      return;
    }
    _controlIn = value;
    markNeedsLayout();
  }

  Offset _controlOut;
  Offset get controlOut => _controlOut;
  set controlOut(Offset value) {
    if (value == _controlOut) {
      return;
    }
    _controlOut = value;
    markNeedsLayout();
  }

  @override
  void onThemeChanged() {
    controlLine.color = theme.colors.keyMarqueeStroke;
  }

  @override
  void performLayout() {
    cubic.reset();
    cubic.moveTo(0, size.height - renderPadding);

    var heightRange = size.height - 2 * renderPadding;

    _renderIn = Offset(_controlIn.dx * size.width,
        renderPadding + heightRange - _controlIn.dy * heightRange);
    _renderOut = Offset(_controlOut.dx * size.width,
        renderPadding + heightRange - _controlOut.dy * heightRange);
    cubic.cubicTo(
      _renderIn.dx,
      _renderIn.dy,
      _renderOut.dx,
      _renderOut.dy,
      size.width,
      renderPadding,
    );
  }

  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {
    canvas.drawPath(cubic, interpolationPaint);

    canvas.drawLine(
        Offset(0, size.height - renderPadding), _renderIn, controlLine);

    canvas.drawLine(Offset(size.width, renderPadding), _renderOut, controlLine);
  }
}

class _EmptyPreviewRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double normalizedTime;

  const _EmptyPreviewRenderer({
    @required this.theme,
    @required this.normalizedTime,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _EmptyPreviewRenderBox()
        ..theme = theme
        ..normalizedTime = normalizedTime;

  @override
  void updateRenderObject(
      BuildContext context, _EmptyPreviewRenderBox renderObject) {
    renderObject
      ..theme = theme
      ..normalizedTime = normalizedTime;
  }
}

class _EmptyPreviewRenderBox extends _InterpolationRenderBox {
  @override
  bool get sizedByParent => true;

  @override
  void paintInterpolation(Canvas canvas) {}
}
