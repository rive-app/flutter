import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/animation/timeline_render_box.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

class Playhead extends StatelessWidget {
  final RiveThemeData theme;

  const Playhead({
    @required this.theme,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ActiveFile.of(context).editingAnimationManager,
      builder: (context, EditingAnimationManager editingAnimation, _) =>
          ValueStreamBuilder<TimelineViewport>(
        stream: editingAnimation.viewport,
        builder: (context, viewportSnapshot) => ValueStreamBuilder<double>(
          stream: editingAnimation.currentTime,
          builder: (context, timeSnapshot) {
            return _PlayheadRenderer(
              theme: theme,
              viewport: viewportSnapshot.data,
              time: timeSnapshot.data,
            );
          },
        ),
      ),
    );
  }
}

class _PlayheadRenderer extends LeafRenderObjectWidget {
  final TimelineViewport viewport;
  final double time;
  final RiveThemeData theme;

  const _PlayheadRenderer({
    @required this.viewport,
    @required this.time,
    @required this.theme,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _PlayheadRenderObject()
      ..viewport = viewport
      ..time = time
      ..theme = theme;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _PlayheadRenderObject renderObject) {
    renderObject
      ..viewport = viewport
      ..time = time
      ..theme = theme;
  }
}

class _PlayheadRenderObject extends TimelineRenderBox {
  double _time;
  static const double _arrowRadius = 5;
  final Paint _playhead = Paint()
    ..isAntiAlias = false
    ..strokeWidth = 1;
  final Paint _arrowPaint = Paint();
  final Path _arrow = Path()
    ..moveTo(-_arrowRadius, 0)
    ..lineTo(0, 9)
    ..lineTo(_arrowRadius, 0)
    ..close();

  double _secondsStart = 0;

  double get time => _time;
  set time(double value) {
    if (_time == value) {
      return;
    }
    _time = value;
    markNeedsPaint();
  }

  @override
  void onThemeChanged(RiveThemeData theme) {
    _arrowPaint.color =
        _playhead.color = theme.colors.timelineViewportControlsGrabber;
  }

  @override
  bool get sizedByParent => true;

  @override
  void performLayout() {
    super.performLayout();
    if (viewport == null) {
      return;
    }
    var marginLeft = theme.dimensions.timelineMarginLeft;
    _secondsStart = viewport.startSeconds - marginLeft * secondsPerPixel;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    canvas.save();
    var x = (time / viewport.fps - _secondsStart) / secondsPerPixel;
    canvas.clipRect(offset & size);
    canvas.translate(
        (offset.dx + x).roundToDouble() + 0.5, (offset.dy).roundToDouble());
    canvas.drawPath(_arrow, _arrowPaint);
    canvas.drawLine(const Offset(0, 8), Offset(0, size.height), _playhead);
    canvas.restore();
  }
}
