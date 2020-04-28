import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/animation/animation_panel_contents.dart';
import 'package:rive_editor/widgets/common/active_artboard.dart';
import 'package:rive_editor/widgets/common/animated_factor_builder.dart';
import 'package:rive_editor/widgets/common/fractional_intrinsic_height.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

/// Shell for the animation panel that allows it to slide up from the bottom
/// when animation mode is activated. See [AnimationPanelContents] for the
/// various component widgets that actually make up the panel.
class AnimationPanel extends StatefulWidget {
  @override
  _AnimationPanelState createState() => _AnimationPanelState();
}

class _AnimationPanelState extends State<AnimationPanel>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    var activeFile = ActiveFile.of(context);
    return ValueListenableBuilder(
      valueListenable: activeFile.mode,
      child: AnimationPanelContents(),
      builder: (context, EditorMode mode, child) {
        return AnimatedFactorBuilder(
          child: child,
          factor: mode == EditorMode.animate ? 1 : 0,
          builder: (context, factor, child) => FractionalIntrinsicHeight(
            heightFactor: factor,
            child: ResizePanel(
              hitSize: 10,
              direction: ResizeDirection.vertical,
              side: ResizeSide.start,
              min: 300,
              max: 600,
              child: _PanelShadow(
                show: factor > 0,
                // Don't add the animation panel contents (or the animations
                // managers) to the layout if we're not showing the panel at
                // all, save some cycles.
                child: factor != 0
                    ? AnimationsProvider(
                        activeArtboard: ActiveArtboard.of(context),
                        child: EditingAnimationProvider(child: child),
                      )
                    : const SizedBox(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thin gradient shown at the top of the animation panel to make it look like
/// it's floating above the other panels. In reality it's layed out inline with
/// them such that the scrollbars in those other panels only consume the space
/// visually available (if the animation panel floated above them, they'd be
/// scrolling behind the animation panel).
class _PanelShadow extends StatelessWidget {
  final bool show;
  final Widget child;

  const _PanelShadow({
    Key key,
    this.show,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      children: [
        if (show)
          Positioned(
            top: -10,
            height: 10,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _PanelShadowPainter(),
            ),
          ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _PanelShadowPainter extends CustomPainter {
  final _paint = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, 10),
      [
        const Color(0x00000000),
        const Color(0x1A000000),
      ],
    );
  @override
  bool shouldRepaint(_PanelShadowPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _paint);
  }
}
