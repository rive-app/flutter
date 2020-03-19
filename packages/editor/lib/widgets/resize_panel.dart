import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cursor/cursor_view.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

import 'common/cursor_icon.dart';
import 'ignore_mouse.dart';

enum ResizeDirection { vertical, horizontal }
enum ResizeSide { start, end }

class ResizePanel extends StatefulWidget {
  final double max;
  final double min;
  final ResizeDirection direction;
  final ResizeSide side;
  final Widget child;
  final double hitSize;

  const ResizePanel({
    Key key,
    this.max,
    this.min,
    this.direction,
    this.side,
    this.child,
    this.hitSize = 10,
  }) : super(key: key);

  @override
  _ResizePanelState createState() => _ResizePanelState();
}

class _ResizePanelState extends State<ResizePanel> {
  double _size;
  double _dragStartPosition;
  double _dragStartSize;
  bool _isLit = false;
  bool _isDragging = false;
  bool _showDragEdge = false;
  Timer _lightTimer;
  OverlayEntry _resizeOverlay;

  @override
  void initState() {
    _size = widget.min;
    super.initState();
  }

  void _updateCursor(BuildContext context) {
    if (_isLit) {
      _showResizeCursor(context, const Duration(milliseconds: 500));
    } else if (_isDragging) {
      _showResizeCursor(context, const Duration(milliseconds: 0));
    } else {
      _hideResizeCursor(context);
    }
  }

  /// When we show the resize cursor, we also create an overlay that allows us
  /// to detect drag operations on the edge of resize panel.
  void _showResizeCursor(BuildContext context, Duration delay) {
    if (RiveContext.of(context).isDragging) {
      return;
    }
    if (_resizeOverlay != null) {
      return;
    }
    CursorIcon.show(
      context,
      widget.direction == ResizeDirection.vertical
          ? 'cursor-resize-vertical'
          : 'cursor-resize-horizontal',
    );
    _lightTimer?.cancel();

    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    _resizeOverlay?.remove();

    double left = 0, top = 0, width = 0, height = 0;
    switch (widget.direction) {
      case ResizeDirection.horizontal:
        height = size.height;
        width = widget.hitSize;
        top = offset.dy;
        if (widget.side == ResizeSide.start) {
          left = offset.dx - widget.hitSize;
        } else {
          left = offset.dx + size.width;
        }
        break;
      case ResizeDirection.vertical:
        height = widget.hitSize;
        width = size.width;
        left = offset.dx;
        if (widget.side == ResizeSide.start) {
          top = offset.dy - widget.hitSize;
        } else {
          top = offset.dy + size.height;
        }
        break;
    }
    _resizeOverlay = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return Positioned(
            key: _key,
            left: left,
            top: top,
            width: width,
            height: height,
            child: detectDrag(
              // Set this to Colors.red to see the drag overlay created to help
              // gesture detect.
              Container(color: Colors.transparent),
            ),
          );
        });

    Overlay.of(context).insert(_resizeOverlay);

    _lightTimer = Timer(delay, () {
      setState(() {
        _showDragEdge = true;
      });
    });
  }

  void _hideResizeCursor(BuildContext context) {
    Cursor.reset(context);
    _lightTimer?.cancel();
    _resizeOverlay?.remove();
    _resizeOverlay = null;
    setState(() {
      _showDragEdge = false;
    });
  }

  Positioned position(double size, double offset, Widget child) {
    switch (widget.direction) {
      case ResizeDirection.horizontal:
        return Positioned(
            right: widget.side == ResizeSide.start ? null : offset,
            left: widget.side == ResizeSide.end ? null : offset,
            width: size,
            top: 0,
            bottom: 0,
            child: child);
      case ResizeDirection.vertical:
        return Positioned(
            bottom: widget.side == ResizeSide.start ? null : offset,
            top: widget.side == ResizeSide.end ? null : offset,
            height: size,
            left: 0,
            right: 0,
            child: child);
    }
    return Positioned(
      child: child,
    );
  }

  final Key _key = GlobalKey();
  GestureDetector detectDrag(Widget child) {
    bool isHorizontal = widget.direction == ResizeDirection.horizontal;
    bool isVertical = widget.direction == ResizeDirection.vertical;
    return GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: isVertical
            ? (details) {
                _dragStartSize = _size;
                _dragStartPosition = details.globalPosition.dy;
                setState(() {
                  _isDragging = true;
                  _updateCursor(context);
                });
              }
            : null,
        onVerticalDragEnd: isVertical
            ? (details) {
                _resizeOverlay?.remove();
                _resizeOverlay = null;
                setState(() {
                  _isDragging = false;
                  _updateCursor(context);
                });
              }
            : null,
        onVerticalDragUpdate: isVertical
            ? (details) {
                var diff = details.globalPosition.dy - _dragStartPosition;

                var size = widget.side == ResizeSide.end
                    ? _dragStartSize + diff
                    : _dragStartSize - diff;

                setState(() {
                  _size = size.clamp(widget.min, widget.max).roundToDouble();
                });
              }
            : null,
        onHorizontalDragStart: isHorizontal
            ? (details) {
                _dragStartSize = _size;
                _dragStartPosition = details.globalPosition.dx;
                setState(() {
                  _isDragging = true;
                  _updateCursor(context);
                });
              }
            : null,
        onHorizontalDragEnd: isHorizontal
            ? (details) {
                _resizeOverlay?.remove();
                _resizeOverlay = null;
                setState(() {
                  _isDragging = false;
                  _updateCursor(context);
                });
              }
            : null,
        onHorizontalDragUpdate: isHorizontal
            ? (details) {
                var diff = details.globalPosition.dx - _dragStartPosition;

                var size = widget.side == ResizeSide.end
                    ? _dragStartSize + diff
                    : _dragStartSize - diff;

                setState(() {
                  _size = size.clamp(widget.min, widget.max).roundToDouble();
                });
              }
            : null,
        child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.direction == ResizeDirection.horizontal ? _size : null,
      height: widget.direction == ResizeDirection.vertical ? _size : null,
      child: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          Positioned.fill(
            child: IgnoreMouse(
              isIgnoring: _isDragging,
              child: widget.child,
            ),
          ),
          position(
            widget.hitSize,
            // -widget.hitSize/2,
            -widget.hitSize,
            MouseRegion(
              opaque: false,
              onEnter: (details) {
                setState(() {
                  _isLit = true;
                  _updateCursor(context);
                });
              },
              onExit: (details) {
                setState(() {
                  _isLit = false;
                  _updateCursor(context);
                });
              },
              child: Stack(
                overflow: Overflow.visible,
                children: [
                  position(
                    2,
                    widget.hitSize,
                    Container(color: _showDragEdge ? Colors.blue : null),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
