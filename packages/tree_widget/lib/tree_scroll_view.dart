import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tree_widget/tree_style.dart';

/// Helper to build a scrollview for a tree composed with a list of slivers.
/// Automatically adds the top and bottom padding from the tree style.
class TreeScrollView extends StatelessWidget {
  final TreeStyle style;
  final List<Widget> slivers;
  final ScrollController scrollController;
  final Key center;
  const TreeScrollView({
    Key key,
    this.style,
    this.slivers,
    this.scrollController,
    this.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: _InvertedDrawOrderScrollView(
          // reverse: true,
          controller: scrollController,

          // This keeps things highly performant, we don't want any overdraw.
          // Flutter uses this for semantics to give feedback on what's offscreen,
          // but for now we can optimize this out.
          cacheExtent: 0,
          slivers: [
            // Add top padding (can't use Sliver padding, as using one with empty
            // sliver causes bugs with virtualization).
            SliverToBoxAdapter(child: SizedBox(height: style.padding.top)),

            ...slivers,

            // Add bottom padding
            SliverToBoxAdapter(child: SizedBox(height: style.padding.bottom)),
          ]),
    );
  }
}

/// A CustomScrollView that draws and hitDetects content in reverse order (top
/// to bottom). This allows items that come after to also draw after, so footers
/// can draw over the content that comes before them.
class _InvertedDrawOrderScrollView extends CustomScrollView {
  const _InvertedDrawOrderScrollView({
    Key key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    Key center,
    double anchor = 0.0,
    double cacheExtent,
    List<Widget> slivers,
    int semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
  }) : super(
            key: key,
            scrollDirection: scrollDirection,
            reverse: reverse,
            controller: controller,
            primary: primary,
            physics: physics,
            shrinkWrap: false,
            center: center,
            anchor: anchor,
            cacheExtent: cacheExtent,
            semanticChildCount: semanticChildCount,
            dragStartBehavior: dragStartBehavior,
            slivers: slivers);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    return _InvertedDrawOrderViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
    );
  }
}

class _InvertedDrawOrderViewport extends Viewport {
  _InvertedDrawOrderViewport({
    Key key,
    AxisDirection axisDirection = AxisDirection.down,
    AxisDirection crossAxisDirection,
    double anchor = 0.0,
    @required ViewportOffset offset,
    Key center,
    double cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    List<Widget> slivers = const <Widget>[],
  }) : super(
          key: key,
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          anchor: anchor,
          offset: offset,
          center: center,
          cacheExtent: cacheExtent,
          cacheExtentStyle: cacheExtentStyle,
          slivers: slivers,
        );

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return _InvertedDrawOrderRenderViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
    );
  }
}

class _InvertedDrawOrderRenderViewport extends RenderViewport {
  _InvertedDrawOrderRenderViewport({
    AxisDirection axisDirection = AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver> children,
    RenderSliver center,
    double cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
  }) : super(
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          offset: offset,
          anchor: anchor,
          children: children,
          center: center,
          cacheExtent: cacheExtent,
        );

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    if (firstChild == null) return;
    RenderSliver child = firstChild;
    while (child != center) {
      yield child;
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      yield child;
      if (child == center) return;
      child = childBefore(child);
    }
  }

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    if (firstChild == null) return;
    RenderSliver child = center;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
    child = childBefore(center);
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }
}
