import 'package:flutter/material.dart';

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

  const OverlayHitDetect({
    Key key,
    this.child,
    this.dragContext,
    this.drag,
    this.endDrag,
  }) : super(key: key);

  @override
  _OverlayHitDetectState createState() => _OverlayHitDetectState();
}

class _OverlayHitDetectState extends State<OverlayHitDetect> {
  OverlayEntry _resizeOverlay;

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
      onHover: (details) => _prepHitArea(),
      onEnter: (details) => _prepHitArea(),
      onExit: (_) {
        _resizeOverlay?.remove();
        _resizeOverlay = null;
      },
      child: widget.child,
    );
  }
}
