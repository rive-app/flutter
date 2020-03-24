import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef EventCallback = void Function(PropagatingEvent);

/// Helper class to detect clicks and double clicks while stile propagating
/// events up the widget hierarchy (doesn't capture like GestureDetector).
class ClickListener extends StatefulWidget {
  final EventCallback onDoubleClick;
  final EventCallback onClick;
  final Widget child;
  final bool isListening;

  const ClickListener({
    Key key,
    this.onDoubleClick,
    this.onClick,
    this.child,
    this.isListening = true,
  }) : super(key: key);

  @override
  _ClickListenerState createState() => _ClickListenerState();
}

class _ClickListenerState extends State<ClickListener> {
  DateTime _firstClickTime;

  @override
  Widget build(BuildContext context) {
    return widget.isListening
        ? PropagatingListener(
            behavior: HitTestBehavior.translucent,
            onPointerUp: (event) {
              var time = DateTime.now();
              if (_firstClickTime != null) {
                var diff = time.difference(_firstClickTime);
                _firstClickTime = time;
                if (diff > kDoubleTapMinTime && diff < kDoubleTapTimeout) {
                  widget.onDoubleClick?.call(event);
                  return;
                }
              } else {
                _firstClickTime = time;
              }

              widget.onClick?.call(event);
            },
            child: IgnorePointer(child: widget.child),
          )
        : widget.child;
  }
}
