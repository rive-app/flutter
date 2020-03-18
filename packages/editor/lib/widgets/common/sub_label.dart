import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Highly specific Rive widget for SubLabels.
///
/// Because these are used a lot, we exclusively parameterize only the values
/// that will change at runtime. Values that are static (like the height of the
/// SubLabel) are not exposed. This widget saves us from wrapping things in
/// Containers with Padding and BoxDecorations which create multile
/// RenderObjects. A single view in Rive can have 30+ of these on screen at a
/// single time, so we simplify and optimize with this single render object
/// widget.
class SubLabel extends SingleChildRenderObjectWidget {
  final TextStyle style;
  final String label;

  const SubLabel({
    Key key,
    this.label,
    this.style,
    Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  _RenderSubLabel createRenderObject(BuildContext context) {
    return _RenderSubLabel(label: label, style: style);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSubLabel renderObject) {
    renderObject
      ..label = label
      ..style = style;
  }
}

class _RenderSubLabel extends RenderShiftedBox {
  _RenderSubLabel({
    RenderBox child,
    TextStyle style,
    String label,
  })  : _style = style,
        _label = label,
        super(child);

  static const double offset = 3;

  TextStyle _style;
  String _label;
  ui.Paragraph _paragraph;
  Size _paragraphSize;

  String get label => _label;
  set label(String value) {
    if (_label == value) {
      return;
    }
    _label = value;
    markNeedsLayout();
  }

  TextStyle get style => _style;
  set style(TextStyle value) {
    if (_style == value) {
      return;
    }
    _style = value;
    markNeedsLayout();
  }

  double get textHeight => _style.fontSize;

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return child.getMinIntrinsicHeight(max(0, width)) + offset + textHeight;
    }
    return offset;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return child.getMaxIntrinsicHeight(max(0, width)) + offset + textHeight;
    }
    return offset + textHeight;
  }

  @override
  void performLayout() {
    double totalOffset = offset + textHeight;
    final BoxConstraints constraints = this.constraints;
    if (child == null) {
      size = constraints.constrain(Size(
        0,
        totalOffset,
      ));
      return;
    }

    final double deflatedMinHeight =
        max(0.0, constraints.minHeight - totalOffset);

    final BoxConstraints innerConstraints = BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
      minHeight: deflatedMinHeight,
      maxHeight: max(deflatedMinHeight, constraints.maxHeight - totalOffset),
    );

    child.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData as BoxParentData;
    childParentData.offset = const Offset(0, 0);
    size = constraints.constrain(Size(
      child.size.width,
      child.size.height + totalOffset,
    ));

    // layout text
    final style = ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontFamily: _style.fontFamily,
      fontSize: _style.fontSize,
    );
    ui.ParagraphBuilder builder = ui.ParagraphBuilder(style)
      ..pushStyle(
        _style.getTextStyle(),
      );

    var text = _label ?? '';
    builder.addText(text);
    _paragraph = builder.build();
    _paragraph.layout(ui.ParagraphConstraints(width: size.width));
    List<TextBox> boxes = _paragraph.getBoxesForRange(0, text.length);
    _paragraphSize = boxes.isEmpty
        ? Size.zero
        : Size(boxes.last.right - boxes.first.left,
            boxes.last.bottom - boxes.first.top);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (_paragraph != null) {
      context.canvas.drawParagraph(
          _paragraph, Offset(offset.dx, offset.dy + size.height - textHeight));
    }
  }
}
