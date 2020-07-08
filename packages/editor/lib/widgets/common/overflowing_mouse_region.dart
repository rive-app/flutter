import 'dart:ui';

import 'package:core/debounce.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class OverflowingMouseRegion extends StatefulWidget {
  /// See [MouseRegion.onEnter]
  final PointerEnterEventListener onEnter;

  /// See [MouseRegion.onHover]
  final PointerHoverEventListener onHover;

  /// See [MouseRegion.onExit]
  final PointerExitEventListener onExit;

  /// Child widget layed out inline with this widget as a direct descendent.
  final Widget child;

  /// Child widget of the overlay helper, use this to add more gesture
  /// detectors/listeners to the overlay input helper.
  final Widget helperChild;

  const OverflowingMouseRegion({
    Key key,
    this.child,
    this.helperChild,
    this.onEnter,
    this.onHover,
    this.onExit,
  }) : super(key: key);

  @override
  _OverflowingMouseRegionState createState() => _OverflowingMouseRegionState();
}

class _OverflowingMouseRegionState extends State<OverflowingMouseRegion> {
  OverlayEntry _helper;
  Rect _globalRect;
  void _updateHelper() {
    // Create an overlay that we can mouse region.

    _helper?.remove();
    _helper = OverlayEntry(
      maintainState: true,
      builder: (context) {
        return Positioned(
          left: _globalRect.left,
          top: _globalRect.top,
          width: _globalRect.width,
          height: _globalRect.height,
          child: MouseRegion(
            onEnter: widget.onEnter,
            onExit: widget.onExit,
            onHover: widget.onHover,
            child: widget.helperChild,
          ),
        );
      },
    );

    Overlay.of(context).insert(_helper);
  }

  void _layoutChanged(Rect rect) {
    _globalRect = rect;
    debounce(_updateHelper);
  }

  @override
  void dispose() {
    cancelDebounce(_updateHelper);
    _helper?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutDetector(
      layoutChanged: _layoutChanged,
      child: widget.child,
    );
  }
}

typedef LayoutChangedCallback = void Function(Rect);

class LayoutDetector extends SingleChildRenderObjectWidget {
  final LayoutChangedCallback layoutChanged;

  const LayoutDetector({
    Widget child,
    this.layoutChanged,
    Key key,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLayoutDetector()..layoutChanged = layoutChanged;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderLayoutDetector renderObject) {
    renderObject.layoutChanged = layoutChanged;
  }
}

class _RenderLayoutDetector extends RenderProxyBox {
  Rect _layoutRect;
  LayoutChangedCallback _layoutChanged;
  LayoutChangedCallback get layoutChanged => _layoutChanged;
  set layoutChanged(LayoutChangedCallback value) {
    if (value == _layoutChanged) {
      return;
    }
    _layoutChanged = value;
    if (_layoutRect == null) {
      markNeedsPaint();
    } else {
      _layoutChanged?.call(_layoutRect);
    }
  }

  _RenderLayoutDetector({
    RenderBox child,
  }) : super(child);

  void _updateBounds() {
    var rect = localToGlobal(Offset.zero) & size;

    if (rect != _layoutRect) {
      _layoutRect = rect;
      _layoutChanged?.call(_layoutRect);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final layer = _LayoutDetectLayer(_updateBounds);
    context.pushLayer(layer, super.paint, offset);
    super.paint(context, offset);
  }
}

class _LayoutDetectLayer extends ContainerLayer {
  final void Function() addedToScene;

  _LayoutDetectLayer(this.addedToScene);
  @override
  void addToScene(SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    super.addToScene(builder, layerOffset);
    addedToScene();
  }
}
