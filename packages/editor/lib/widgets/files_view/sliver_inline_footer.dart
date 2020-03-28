import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A Sliver that renders inline with list contents but then remains docked at
/// the bottom of the list when it would otherwise be scrolled out of view. 
///
/// Most of the logic here is similar to [RenderSliverScrollingPersistentHeader]
/// but the content is docked to the bottom of the list and otherwise scrolls
/// with the content.
class SliverInlineFooter extends SingleChildRenderObjectWidget {
  const SliverInlineFooter({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverInlineFooter createRenderObject(BuildContext context) =>
      RenderSliverInlineFooter();
}

class RenderSliverInlineFooter extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  double _childPosition;
  RenderSliverInlineFooter({
    RenderBox child,
  }) {
    this.child = child;
  }

  @override
  double childMainAxisPosition(RenderBox child) => 0;

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    assert(geometry.hitTestExtent > 0.0);
    if (child != null) {
      return hitTestBoxChild(BoxHitTestResult.wrap(result), child,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition);
    }
    return false;
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    final SliverConstraints constraints = this.constraints;
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child.size.width;
        break;
      case Axis.vertical:
        childExtent = child.size.height;
        break;
    }

    // If we extend past the bottom of the available viewport's extents, negate
    // our offset in the opposite direction by how much we'd overflow to keep us
    // in the view.
    _childPosition = constraints.remainingPaintExtent > childExtent
        ? 0
        : constraints.remainingPaintExtent - childExtent;
        
    geometry = SliverGeometry(
      paintOrigin: _childPosition,
      scrollExtent: childExtent,
      paintExtent: childExtent,
      cacheExtent: childExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: childExtent,
      maxScrollObstructionExtent: childExtent,
      layoutExtent: childExtent,
      visible: true,
    );
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(child, offset);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return "SliverInlineFooter";
  }
}
