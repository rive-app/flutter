import 'package:core/debounce.dart';
import 'package:cursor/cursor_view.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/cursor_icon.dart';
import 'package:rive_editor/widgets/common/overflowing_mouse_region.dart';
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
  final DragProxy startDrag;
  final DragProxy drag;
  final VoidCallback endDrag;
  final VoidCallback press;
  final Iterable<PackedIcon> customCursorIcon;
  final bool debouncePress;
  final VoidCallback enter;
  final VoidCallback exit;
  final bool dragGlobal;

  const OverlayHitDetect({
    Key key,
    this.child,
    this.dragContext,
    this.startDrag,
    this.drag,
    this.endDrag,
    this.press,
    this.customCursorIcon,
    this.debouncePress = false,
    this.enter,
    this.exit,
    this.dragGlobal = false,
  }) : super(key: key);

  @override
  _OverlayHitDetectState createState() => _OverlayHitDetectState();
}

class _OverlayHitDetectState extends State<OverlayHitDetect> {
  CursorInstance _customCursor;
  bool _isDragging = false;
  // Need to store this otherwise it can cause a context lookup during pointerUp
  // which can trigger after this widget is unmounted causing a  'Looking up a
  // deactivated widget's ancestor is unsafe.' exception.
  Rive _dragOperationOn;

  @override
  void dispose() {
    if (widget.press != null) {
      cancelDebounce(widget.press);
    }
    _customCursor?.remove();
    super.dispose();
  }

  void _dragCallback(DragProxy cb, Offset position, RenderBox dragRenderBox) {
    if (cb == null) {
      return;
    }

    if (widget.dragGlobal) {
      cb.call(
        position,
        Offset(
          (position.dx / context.size.width).clamp(0, 1).toDouble(),
          (position.dy / context.size.height).clamp(0, 1).toDouble(),
        ),
      );
      return;
    }
    var pos = dragRenderBox.globalToLocal(position);

    cb.call(
      pos,
      Offset(
        (pos.dx / dragRenderBox.size.width).clamp(0, 1).toDouble(),
        (pos.dy / dragRenderBox.size.height).clamp(0, 1).toDouble(),
      ),
    );
  }

  RenderBox _draggingRenderBox;

  @override
  Widget build(BuildContext context) {
    return OverflowingMouseRegion(
      onHover: (details) {
        if (RiveContext.find(context).isDragging) {
          return;
        }
        if (widget.customCursorIcon != null) {
          if (_customCursor == null) {
            _customCursor = CursorIcon.show(context, widget.customCursorIcon);
            widget.enter?.call();
          }
        }
        // _prepHitArea();
      },
      onEnter: (details) {
        if (RiveContext.find(context).isDragging) {
          return;
        }
        if (widget.customCursorIcon != null) {
          _customCursor ??= CursorIcon.show(context, widget.customCursorIcon);
        }
        // _prepHitArea();
        widget.enter?.call();
      },
      onExit: (_) {
        if (!_isDragging) {
          _customCursor?.remove();
          _customCursor = null;
        }
        widget.exit?.call();
      },
      child: widget.child,
      helperChild: Listener(
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(),
        onPointerDown: (details) {
          (_dragOperationOn = RiveContext.find(context)).startDragOperation();
          _isDragging = true;
          if (widget.customCursorIcon != null) {
            _customCursor ??= CursorIcon.show(context, widget.customCursorIcon);
          }
          if (widget.press != null) {
            widget.debouncePress ? debounce(widget.press) : widget.press();
          }

          _draggingRenderBox =
              widget.dragContext.findRenderObject() as RenderBox;

          _dragCallback(widget.startDrag, details.position, _draggingRenderBox);
        },
        onPointerMove: (details) =>
            _dragCallback(widget.drag, details.position, _draggingRenderBox),
        onPointerUp: (details) {
          _dragOperationOn?.endDragOperation();
          _isDragging = false;
          _customCursor?.remove();
          _customCursor = null;
          widget.endDrag?.call();
        },
      ),
    );
  }
}
