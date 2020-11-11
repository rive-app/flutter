import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cursor/cursor_view.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/overlay_hit_detect.dart';
import 'package:rive_editor/widgets/ignore_mouse.dart';

enum ResizeDirection { vertical, horizontal }
enum ResizeSide { start, end }

class ResizePanel extends StatefulWidget {
  final double max;
  final double min;
  final double defaultSize;
  final ResizeDirection direction;
  final ResizeSide side;
  final Widget child;
  final double hitSize;
  final double hitOffset;
  final double drawOffset;

  /// You can supply a dead zone to the ResizePanel at the start and the end of
  /// the axis.
  final double deadStart;
  final double deadEnd;

  const ResizePanel({
    Key key,
    this.max,
    this.min,
    this.defaultSize,
    this.direction,
    this.side,
    this.child,
    this.deadStart = 0,
    this.deadEnd = 0,
    this.hitSize = 10,
    this.hitOffset = 0,
    this.drawOffset = 0,
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

  @override
  void dispose() {
    super.dispose();
    _lightTimer?.cancel();
  }

  @override
  void initState() {
    _size = widget.defaultSize ?? widget.min;
    super.initState();
  }

  Positioned position(double size, double offset, Widget child,
      {bool includeDeadZone = false}) {
    switch (widget.direction) {
      case ResizeDirection.horizontal:
        return Positioned(
            right: widget.side == ResizeSide.start ? null : offset,
            left: widget.side == ResizeSide.end ? null : offset,
            width: size,
            top: includeDeadZone ? widget.deadStart : 0,
            bottom: includeDeadZone ? widget.deadEnd : 0,
            child: child);
      case ResizeDirection.vertical:
        return Positioned(
            bottom: widget.side == ResizeSide.start ? null : offset,
            top: widget.side == ResizeSide.end ? null : offset,
            height: size,
            left: includeDeadZone ? widget.deadStart : 0,
            right: includeDeadZone ? widget.deadEnd : 0,
            child: child);
    }
    return Positioned(
      child: child,
    );
  }

  double _dimension(Offset delta) {
    return widget.direction == ResizeDirection.vertical ? delta.dy : delta.dx;
  }

  void _updateDragEdge(BuildContext context) {
    if (CustomCursor.find(context).isHidden) {
      return;
    }
    if (_isLit) {
      _lightTimer?.cancel();
      _lightTimer = Timer(
        const Duration(milliseconds: 500),
        () {
          setState(
            () {
              _showDragEdge = true;
            },
          );
        },
      );
    } else if (_isDragging) {
      _lightTimer?.cancel();
      if (!_showDragEdge) {
        setState(
          () {
            _showDragEdge = true;
          },
        );
      }
    } else {
      _lightTimer?.cancel();
      if (_showDragEdge) {
        setState(
          () {
            _showDragEdge = false;
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.direction == ResizeDirection.horizontal ? _size : null,
      height: widget.direction == ResizeDirection.vertical ? _size : null,
      child: Stack(
        clipBehavior: Clip.none,
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
            -widget.hitSize + widget.hitOffset,
            OverlayHitDetect(
              customCursorIcon: widget.direction == ResizeDirection.vertical
                  ? PackedIcon.cursorResizeVertical
                  : PackedIcon.cursorResizeHorizontal,
              dragGlobal: true,
              dragContext: context,
              enter: () {
                _isLit = true;
                _updateDragEdge(context);
              },
              exit: () {
                _isLit = false;
                _updateDragEdge(context);
              },
              startDrag: (global, _) {
                _dragStartPosition = _dimension(global);
                _dragStartSize = _size;
                _isDragging = true;
                _updateDragEdge(context);
              },
              drag: (global, _) {
                var diff = _dimension(global) - _dragStartPosition;

                var size = widget.side == ResizeSide.end
                    ? _dragStartSize + diff
                    : _dragStartSize - diff;
                _isDragging = true;

                setState(() {
                  _size = size.clamp(widget.min, widget.max).roundToDouble();
                });
                _updateDragEdge(context);
              },
              endDrag: () {
                _isDragging = false;
                _isLit = false;
                _updateDragEdge(context);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  position(
                    2,
                    widget.hitSize + widget.drawOffset,
                    Container(color: _showDragEdge ? Colors.blue : null),
                  ),
                ],
              ),
            ),
            includeDeadZone: true,
          )
        ],
      ),
    );
  }
}
