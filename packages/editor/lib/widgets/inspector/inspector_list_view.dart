import 'dart:math' as math;

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A list view that automatically handles scrolling with the mouse wheel.
class InspectorListView extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;

  const InspectorListView({
    @required this.itemBuilder,
    @required this.itemCount,
    Key key,
  }) : super(key: key);

  @override
  _InspectorListViewState createState() => _InspectorListViewState();
}

class _InspectorListViewState extends State<InspectorListView> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (data) {
        var event = data.pointerEvent as PointerScrollEvent;
        double delta = event.scrollDelta.dy;
        var position = _scrollController.position;
        var newPosition = math.min(
            math.max(position.pixels + delta, position.minScrollExtent),
            position.maxScrollExtent);

        _scrollController.jumpTo(newPosition);
      },
      child: Scrollbar(
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: widget.itemBuilder,
          itemCount: widget.itemCount,
        ),
      ),
    );
  }
}
