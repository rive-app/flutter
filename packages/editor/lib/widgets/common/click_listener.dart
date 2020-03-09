import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Helper class to detect clicks and double clicks while stile propagating
/// events up the widget hierarchy (doesn't capture like GestureDetector).
class ClickListener extends StatefulWidget {
  final VoidCallback onDoubleClick;
  final VoidCallback onClick;
  final Widget child;

  const ClickListener({
    Key key,
    this.onDoubleClick,
    this.onClick,
    this.child,
  }) : super(key: key);

  @override
  _ClickListenerState createState() => _ClickListenerState();
}

class _ClickListenerState extends State<ClickListener> {
  DateTime _firstClickTime;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (_) {
        var time = DateTime.now();
        if (_firstClickTime != null) {
          var diff = time.difference(_firstClickTime);
          _firstClickTime = time;
          if (diff > kDoubleTapMinTime && diff < kDoubleTapTimeout) {
            widget.onDoubleClick?.call();
            return;
          }
        } else {
          _firstClickTime = time;
        }

        widget.onClick?.call();
      },
      child: IgnorePointer(child: widget.child),
    );
  }
}
