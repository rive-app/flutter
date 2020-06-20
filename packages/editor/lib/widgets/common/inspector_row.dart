import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

const double _labelPadding = 16;

const double _columnPadding = 20;

const double _totalPadding = _labelPadding + _columnPadding;

class InspectorRow extends StatelessWidget {
  final Widget label;
  final Widget columnA;
  final Widget columnB;
  final bool expandColumnA;

  const InspectorRow({
    Key key,
    this.label,
    this.columnA,
    this.columnB,
    this.expandColumnA = false,
  })  : assert(!expandColumnA || columnB == null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding around text label to align baseline of combo box. This
        // might need to be handled differently in production to assure
        // rows are of the same heights.
        _InspectorRowSizer(widthFactor: 1 / 3, child: label),
        const SizedBox(
          width: _labelPadding,
        ),
        _InspectorRowSizer(
          widthFactor: expandColumnA ? 2 / 3 : 1 / 3,
          offsetPixelWidth: expandColumnA ? _columnPadding : 0,
          child: columnA,
        ),
        if (columnB != null)
          const SizedBox(
            width: _columnPadding,
          ),
        if (columnB != null)
          _InspectorRowSizer(
            widthFactor: 1 / 3,
            child: columnB,
          ),
      ],
    );
  }
}

class _InspectorRowSizer extends SingleChildRenderObjectWidget {
  final double widthFactor;
  final double offsetPixelWidth;

  const _InspectorRowSizer({
    Key key,
    this.widthFactor = 1,
    this.offsetPixelWidth = 0,
    Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  _RenderInspectorRowSizer createRenderObject(BuildContext context) {
    return _RenderInspectorRowSizer(
      widthFactor: widthFactor,
      offsetPixelWidth: offsetPixelWidth,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderInspectorRowSizer renderObject) {
    renderObject
      ..widthFactor = widthFactor
      ..offsetPixelWidth = offsetPixelWidth;
  }
}

class _RenderInspectorRowSizer extends RenderShiftedBox {
  _RenderInspectorRowSizer({
    RenderBox child,
    double widthFactor,
    double offsetPixelWidth,
  })  : _widthFactor = widthFactor,
        _offsetPixelWidth = offsetPixelWidth,
        super(child);

  double _widthFactor;
  double get widthFactor => _widthFactor;
  set widthFactor(double value) {
    if (_widthFactor == value) {
      return;
    }
    _widthFactor = value;
    markNeedsLayout();
  }

  double _offsetPixelWidth;
  double get offsetPixelWidth => _offsetPixelWidth;
  set offsetPixelWidth(double value) {
    if (_offsetPixelWidth == value) {
      return;
    }
    _offsetPixelWidth = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double width) {
    if (child != null) {
      return child.getMinIntrinsicWidth(max(0, width));
    }
    return 0;
  }

  @override
  double computeMaxIntrinsicWidth(double width) {
    if (child != null) {
      return child.getMaxIntrinsicWidth(max(0, width));
    }
    return 0;
  }

  @override
  void performLayout() {
    var parentConstraints = (parent as RenderBox).constraints;
    double width = (parentConstraints.minWidth - _totalPadding) * widthFactor +
        offsetPixelWidth;

    if (child == null) {
      size = Size(width, 0);
      return;
    }

    child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
    size = child.size;
  }
}