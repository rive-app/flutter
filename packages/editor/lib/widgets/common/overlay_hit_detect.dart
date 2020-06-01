import 'package:cursor/cursor_view.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/cursor_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// A drag callback with local and local normalized (0-1) coordinates.
typedef DragProxy = void Function(Offset local, Offset localNormalized);

/// A mouse click/hit detection helper that can be placed around any item and
/// will use mouse regions to track the visual bounds of the widget and place an
/// overlay when the region can be clicked on. This allows the hit detection to
/// break out of the bounds of the widget which normally isn't possible as
/// Flutter forces the widget's hit area to not exceed that of the parent
/// bounding widget.
class OverlayHitDetect extends StatefulWidget {
  final Widget child;
  final BuildContext dragContext;
  final DragProxy drag;
  final VoidCallback endDrag;
  final VoidCallback press;
  final Iterable<PackedIcon> customCursorIcon;

  const OverlayHitDetect({
    Key key,
    this.child,
    this.dragContext,
    this.drag,
    this.endDrag,
    this.press,
    this.customCursorIcon,
  }) : super(key: key);

  @override
  _OverlayHitDetectState createState() => _OverlayHitDetectState();
}

class _OverlayHitDetectState extends State<OverlayHitDetect> {
  OverlayEntry _resizeOverlay;
  CursorInstance _customCursor;
  bool _isDragging = false;
  // Need to store this otherwise it can cause a context lookup during pointerUp
  // which can trigger after this widget is unmounted causing a  'Looking up a
  // deactivated widget's ancestor is unsafe.' exception.
  Rive _dragOperationOn;

  @override
  void dispose() {
    _customCursor?.remove();
    super.dispose();
  }

  void _prepHitArea([Offset checkPosition]) {
    RenderBox dragRenderBox =
        widget.dragContext.findRenderObject() as RenderBox;
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // If checkPosition was supplied, make sure our offset is within the bounds.
    if (checkPosition != null && !(offset & size).contains(checkPosition)) {
      return;
    }

    _resizeOverlay?.remove();
    _resizeOverlay = OverlayEntry(
      maintainState: true,
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          width: size.width,
          height: size.height,
          child: Listener(
            onPointerDown: (details) {
              (_dragOperationOn = RiveContext.find(context))
                  .startDragOperation();
              _isDragging = true;
              if (widget.customCursorIcon != null) {
                _customCursor ??=
                    CursorIcon.show(context, widget.customCursorIcon);
              }
              widget.press?.call();
            },
            onPointerMove: (details) {
              var pos = dragRenderBox.globalToLocal(details.position);

              widget.drag?.call(
                  pos,
                  Offset(
                      (pos.dx / dragRenderBox.size.width)
                          .clamp(0, 1)
                          .toDouble(),
                      (pos.dy / dragRenderBox.size.height)
                          .clamp(0, 1)
                          .toDouble()));
            },
            onPointerUp: (details) {
              _dragOperationOn?.endDragOperation();
              _isDragging = false;
              _customCursor?.remove();
              _customCursor = null;
              _resizeOverlay?.remove();
              _resizeOverlay = null;
              _prepHitArea(details.position);
              widget.endDrag?.call();
            },
            child: Container(color: Colors.transparent),
          ),
        );
      },
    );

    Overlay.of(context).insert(_resizeOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (details) {
        if (RiveContext.find(context).isDragging) {
          return;
        }
        if (widget.customCursorIcon != null) {
          _customCursor ??= CursorIcon.show(context, widget.customCursorIcon);
        }
        _prepHitArea();
      },
      onEnter: (details) {
        if (RiveContext.find(context).isDragging) {
          return;
        }
        if (widget.customCursorIcon != null) {
          _customCursor ??= CursorIcon.show(context, widget.customCursorIcon);
        }
        _prepHitArea();
      },
      onExit: (_) {
        if (!_isDragging) {
          _customCursor?.remove();
          _customCursor = null;
        }
        _resizeOverlay?.remove();
        _resizeOverlay = null;
      },
      child: widget.child,
    );
  }
}
