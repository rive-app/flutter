import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MarqueeScrollView extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final bool enable;

  const MarqueeScrollView({
    Key key,
    @required this.child,
    @required this.controller,
    @required this.enable,
  }) : super(key: key);

  @override
  _MarqueeScrollViewState createState() => _MarqueeScrollViewState();
}

class _MarqueeScrollViewState extends State<MarqueeScrollView> {
  bool _dragging = false;
  bool _enable = true;
  Offset _start, _end;

  @override
  void didUpdateWidget(MarqueeScrollView oldWidget) {
    if (oldWidget.enable != widget.enable) {
      if (mounted)
        setState(() {
          _enable = widget.enable;
        });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, dimens) => Listener(
        onPointerDown: (event) {
          _start = event.localPosition;
          _end = event.localPosition;
          _drag(true);
        },
        onPointerMove: (event) {
          _end = event.localPosition;
          if (mounted) setState(() {});
        },
        onPointerUp: (event) {
          _start = null;
          _end = null;
          _drag(false);
        },
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (details) {
          if (details is PointerScrollEvent) {
            RenderBox getBox = context.findRenderObject() as RenderBox;
            var local = getBox.globalToLocal(details.position);
            // rive.stage.mouseWheel(local.dx, local.dy, details.scrollDelta.dx,
            //     details.scrollDelta.dy);
            final _current = widget.controller.offset;
            if (details.scrollDelta.dy.isNegative && _current == 0) {
            } else {
              widget.controller.jumpTo(_current + details.scrollDelta.dy);
            }
          }
        },
        child: Stack(
          children: <Widget>[
            AbsorbPointer(
              absorbing: _dragging,
              child: widget.child,
            ),
            if (_enable && _dragging) ...[_buildMarquee(dimens)],
          ],
        ),
      ),
    );
  }

  Positioned _buildMarquee(BoxConstraints dimens) {
    final _rect = Rect.fromPoints(_start, _end);
    return Positioned.fromRect(
      rect: _rect,
      child: Container(color: Colors.blue.withOpacity(0.2)),
    );
  }

  void _drag(bool value) {
    if (mounted)
      setState(() {
        _dragging = value;
      });
  }
}
