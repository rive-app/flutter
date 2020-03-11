import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/overlay_hit_detect.dart';
import 'package:rive_editor/widgets/inspector/color/color_grabber.dart';

typedef ChangeValueCallback = void Function(double);

/// A slider that modifies some property of a color. Has the option to build a
/// different background which varies depending on type of slider. Provides a
/// changeValue callback invoked when the grabber is dragged or the
/// track/background is pressed on.
///
/// Two example [ColorSlider]s with different background builders:
///
/// ![](https://assets.rvcd.in/inspector/color/color_sliders.png)
class ColorSlider extends StatelessWidget {
  final Color color;
  final WidgetBuilder background;
  final double value;
  final ChangeValueCallback changeValue;
  final VoidCallback completeChange;

  const ColorSlider({
    Key key,
    this.color,
    this.background,
    this.value,
    this.changeValue,
    this.completeChange,
  }) : super(key: key);

  static const double height = 10;
  static const double grabberSize = 11;
  static const double minX = grabberSize / 2;

  double _localPositionToValue(double localX, double width) =>
      ((localX - minX) / (width - grabberSize)).clamp(0, 1).toDouble();

  GestureDetector _detectDrag({BuildContext context, Widget child}) =>
      GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.start,
          onTapDown: (details) => changeValue?.call(
                _localPositionToValue(
                  details.localPosition.dx,
                  context.size.width,
                ),
              ),
          onHorizontalDragUpdate: (details) => changeValue?.call(
                _localPositionToValue(
                  details.localPosition.dx,
                  context.size.width,
                ),
              ),
          onTapUp: (_) => completeChange?.call(),
          child: child);

  @override
  Widget build(BuildContext context) {
    return _detectDrag(
      context: context,
      child: Container(
        height: height,
        child: Stack(
          overflow: Overflow.visible,
          children: [
            Positioned.fill(
              child: background(context),
            ),
            CustomSingleChildLayout(
              child: OverlayHitDetect(
                dragContext: context,
                drag: (position, _) => changeValue?.call(
                  _localPositionToValue(
                    position.dx,
                    context.size.width,
                  ),
                ),
                child: ColorGrabber(
                  color: color,
                  size: const Size(
                    grabberSize,
                    grabberSize,
                  ),
                ),
              ),
              delegate: _ColorSliderPositionerDelegate(value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom positioner for the color slider's grabber.
class _ColorSliderPositionerDelegate extends SingleChildLayoutDelegate {
  final double value;

  _ColorSliderPositionerDelegate(this.value);

  @override
  bool shouldRelayout(_ColorSliderPositionerDelegate oldDelegate) {
    return oldDelegate.value != value;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset((size.width - childSize.width) * value,
        size.height / 2 - childSize.height / 2);
  }
}
