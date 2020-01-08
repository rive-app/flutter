import 'package:flutter/material.dart';

/// Use this widget to block children from receiving hover events (effectively
/// blocks mouse regions).
class IgnoreMouse extends StatelessWidget {
  final bool isIgnoring;
  final Widget child;

  const IgnoreMouse({Key key, this.isIgnoring, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: child),
        isIgnoring
            ? Positioned.fill(
                child: MouseRegion(
                  opaque: isIgnoring,
                  child: Container(
                    color: Colors.red.withOpacity(0.0),
                  ),
                ),
              )
            : null,
      ].where((item) => item != null).toList(growable: false),
    );
  }
}
