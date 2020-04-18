import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

/// Container for the animation panel that allows it to slide up from the bottom
/// when animation mode is activated.
class AnimationPanel extends StatelessWidget {
  final Widget child;

  const AnimationPanel({Key key, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: const Cubic(0.8, 0, 0, 1),
          top: 0,
          bottom:0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Expanded(child: SizedBox()),
              const ResizePanel(
                hitSize: 10,
                direction: ResizeDirection.vertical,
                side: ResizeSide.start,
                min: 235,
                max: 500,
                child: ColoredBox(
                  color: Color(0x99000000),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
