import 'package:flutter/material.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
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
        Positioned.fill(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Expanded(child: SizedBox()),
              _SlidingAnimationPanel(
                child: const ColoredBox(
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

class _AnimatedOffsetBuilder extends StatefulWidget {
  final double offset;
  final Widget Function(BuildContext, double, Widget) builder;
  final Widget child;

  const _AnimatedOffsetBuilder({
    Key key,
    this.offset,
    this.builder,
    this.child,
  }) : super(key: key);
  @override
  __AnimatedOffsetBuilderState createState() => __AnimatedOffsetBuilderState();
}

class __AnimatedOffsetBuilderState extends State<_AnimatedOffsetBuilder>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  double _animatedOffset;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    controller.value = _animatedOffset = widget.offset;
    // controller.animateTo(widget.offset);
    controller.addListener(() {
      setState(() {
        _animatedOffset = Curves.easeInOut.transform(controller.value);
      });
    });
  }

  @override
  void didUpdateWidget(_AnimatedOffsetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offset != widget.offset) {
      controller.animateTo(widget.offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animatedOffset, widget.child);
  }
}

class _SlidingAnimationPanel extends StatelessWidget {
  final Widget child;

  const _SlidingAnimationPanel({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var activeFile = ActiveFile.of(context);
    return ValueListenableBuilder(
      valueListenable: activeFile.mode,
      child: child,
      builder: (context, EditorMode mode, child) {
        return _AnimatedOffsetBuilder(
          offset: mode == EditorMode.animate ? 0 : 1,
          child: child,
          builder: (context, offset, child) {
            if (offset == 1) {
              return child;
            }
            return ResizePanel(
              hitSize: 10,
              direction: ResizeDirection.vertical,
              side: ResizeSide.start,
              min: 235,
              max: 500,
              child: CustomSingleChildLayout(
                delegate: _AnimationPanelLayout(
                  offscreen: offset,
                ),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

/// Custom positioner to help align the animation panel so it can slide off
/// screen even though it's of dynamic size.
class _AnimationPanelLayout extends SingleChildLayoutDelegate {
  final double offscreen;

  _AnimationPanelLayout({this.offscreen});

  @override
  bool shouldRelayout(_AnimationPanelLayout oldDelegate) {
    return oldDelegate.offscreen != offscreen;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0, childSize.height * offscreen);
  }
}
