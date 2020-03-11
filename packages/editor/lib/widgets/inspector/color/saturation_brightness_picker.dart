import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/overlay_hit_detect.dart';
import 'package:rive_editor/widgets/inspector/color/color_grabber.dart';
import 'package:rive_editor/widgets/inspector/color/color_slider.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';

/// The saturation/brightness graph with ColorGrabber to change the current
/// saturation/brightness value.
/// ![](https://assets.rvcd.in/inspector/color/saturation_brightness.png)
class SaturationBrightnessPicker extends StatelessWidget {
  final HSVColor hsv;
  final ChangeColor change;
  final VoidCallback complete;

  const SaturationBrightnessPicker({
    @required this.hsv,
    @required this.change,
    @required this.complete,
    Key key,
  }) : super(key: key);

  HSVColor _localPositionToValue(Offset offset, Size size) {
    var sb = Offset((offset.dx / size.width).clamp(0, 1).toDouble(),
        (offset.dy / size.height).clamp(0, 1).toDouble());
    return HSVColor.fromAHSV(
      hsv.alpha,
      hsv.hue,
      sb.dx,
      1 - sb.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.start,
      onTapDown: (details) => change?.call(
        _localPositionToValue(
          details.localPosition,
          context.size,
        ),
      ),
      onHorizontalDragUpdate: (details) => change?.call(
        _localPositionToValue(
          details.localPosition,
          context.size,
        ),
      ),
      onTapUp: (_) => complete?.call(),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SaturationBrightnessPainter(
                HSVColor.fromAHSV(
                  1,
                  hsv.hue,
                  1,
                  1,
                ).toColor(),
              ),
            ),
          ),
          CustomSingleChildLayout(
            delegate: _SaturationBrightnessGrabberPositioner(
              hsv.saturation,
              1 - hsv.value,
            ),
            child: OverlayHitDetect(
              dragContext: context,
              drag: (_, normalizedPosition) {
                change(
                  HSVColor.fromAHSV(
                    hsv.alpha,
                    hsv.hue,
                    normalizedPosition.dx,
                    1 - normalizedPosition.dy,
                  ),
                );
              },
              child: ColorGrabber(
                color: HSVColor.fromAHSV(
                  1,
                  hsv.hue,
                  hsv.saturation,
                  hsv.value,
                ).toColor(),
                size: const Size(
                  ColorSlider.grabberSize,
                  ColorSlider.grabberSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A layout delegate to help position the color grabber in the saturation
/// brightness graph.
class _SaturationBrightnessGrabberPositioner extends SingleChildLayoutDelegate {
  final double x;
  final double y;

  _SaturationBrightnessGrabberPositioner(this.x, this.y);

  @override
  bool shouldRelayout(_SaturationBrightnessGrabberPositioner oldDelegate) {
    return oldDelegate.x != x || oldDelegate.y != y;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(size.width * x - childSize.width / 2,
        size.height * y - childSize.height / 2);
  }
}

/// Painter for the saturation/brightness graph.
class _SaturationBrightnessPainter extends CustomPainter {
  const _SaturationBrightnessPainter(this.color);

  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()..color = color,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00000000),
              Color(0xFF000000),
            ],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(_SaturationBrightnessPainter oldPaint) =>
      oldPaint.color != color;
}
