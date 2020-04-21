import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Widget that assumes the size of its child with the height multiplied by a
/// [heightFactor].
class FractionalIntrinsicHeight extends SingleChildRenderObjectWidget {
  final double heightFactor;

  const FractionalIntrinsicHeight({
    Key key,
    this.heightFactor = 1,
    Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  _RenderFractionalIntrinsicHeight createRenderObject(BuildContext context) {
    return _RenderFractionalIntrinsicHeight(heightFactor: heightFactor);
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderFractionalIntrinsicHeight renderObject) {
    renderObject.heightFactor = heightFactor;
  }
}

class _RenderFractionalIntrinsicHeight extends RenderShiftedBox {
  _RenderFractionalIntrinsicHeight({
    RenderBox child,
    double heightFactor,
  })  : _heightFactor = heightFactor,
        super(child);

  double _heightFactor;
  double get heightFactor => _heightFactor;
  set heightFactor(double value) {
    if (_heightFactor == value) {
      return;
    }
    _heightFactor = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return child.getMinIntrinsicHeight(max(0, width));
    }
    return 0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return child.getMaxIntrinsicHeight(max(0, width));
    }
    return 0;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;

    child.layout(constraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData as BoxParentData;
    childParentData.offset = const Offset(0, 0);
    size = constraints.constrain(Size(
      child.size.width,
      child.size.height * _heightFactor,
    ));
  }
}
