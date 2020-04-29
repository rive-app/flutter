import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
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
    var editingAnimation = EditingAnimationProvider.of(context);
    return ValueStreamBuilder<TimelineViewport>(
      stream: editingAnimation.viewport,
      builder: (context, viewportSnapshot) => ValueStreamBuilder<int>(
        stream: editingAnimation.currentTime,
        builder: (context, timeSnapshot) {
          return _PlayheadRenderer(
            theme: theme,
            viewport: viewportSnapshot.data,
            time: timeSnapshot.data,
          );
        },
      ),
    );
  }
}

class _PlayheadRenderer extends LeafRenderObjectWidget {
  final TimelineViewport viewport;
  final int time;
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
  int _time;
  static const double _arrowRadius = 5;
  final Paint _playhead = Paint()..isAntiAlias = false;
  final Paint _arrowPaint = Paint();
  final Path _arrow = Path()
    ..moveTo(-_arrowRadius, 12)
    ..lineTo(0, 21)
    ..lineTo(_arrowRadius, 12)
    ..close();

  double _secondsStart = 0;

  int get time => _time;
  set time(int value) {
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
    canvas.drawLine(const Offset(0, 20), Offset(0, size.height), _playhead);
    canvas.restore();
  }
}
