import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:provider/provider.dart';

class MarqueeScrollView extends StatefulWidget {
  final Widget child;
  final bool enable;
  final ScrollController controller;
  final Rive rive;

  const MarqueeScrollView({
    Key key,
    @required this.child,
    @required this.enable,
    @required this.controller,
    @required this.rive,
  }) : super(key: key);

  @override
  _MarqueeScrollViewState createState() => _MarqueeScrollViewState();
}

class _MarqueeScrollViewState extends State<MarqueeScrollView> {
  bool _dragging = false;
  bool _enable = true;
  Offset _start, _end;

  @override
  void initState() {
    widget.controller.addListener(() {
      widget.rive.fileBrowser.scrollOffset.value = widget.controller.offset;
    });
    super.initState();
  }

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
    final _rive = Provider.of<Rive>(context, listen: false);
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
          final _rect = Rect.fromPoints(_start, _end);
          _rive.fileBrowser.rectChanged(_rect, _rive);
        },
        onPointerUp: (event) {
          _start = null;
          _end = null;
          _drag(false);
          _rive.fileBrowser.rectChanged(null, _rive);
        },
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (details) {
          if (details is PointerScrollEvent) {
            RenderBox getBox = context.findRenderObject() as RenderBox;
            var local = getBox.globalToLocal(details.position);
            // rive.stage.mouseWheel(local.dx, local.dy, details.scrollDelta.dx,
            //     details.scrollDelta.dy);
            final _controller = widget.controller;
            final _offset = _controller.offset;
            if (details.scrollDelta.dy.isNegative && _offset == 0) {
            } else {
              final _newOffset = _offset + details.scrollDelta.dy;
              _controller.jumpTo(_newOffset);
              widget.rive.fileBrowser.scrollOffset.value = _newOffset;
            }
          }
        },
        child: Stack(
          children: <Widget>[
            AbsorbPointer(
              absorbing: _dragging,
              child: widget.child,
            ),
            if (_enable && _dragging) ...[
              ValueListenableBuilder<double>(
                valueListenable: widget.rive.fileBrowser.scrollOffset,
                builder: (context, offset, child) =>
                    _buildMarquee(dimens, _rive, offset ?? 0.0),
              )
            ],
          ],
        ),
      ),
    );
  }

  Positioned _buildMarquee(BoxConstraints dimens, Rive rive, double offset) {
    Rect _rect = Rect.fromPoints(_start, _end);
    _rect = Rect.fromPoints(
        Offset(_rect.topLeft.dx, _rect.topLeft.dy - offset), _rect.bottomRight);
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
