import 'dart:ui';

import 'package:rive_editor/widgets/theme.dart';

/// A high contrast tooltip usually drawn by a StageTool over stage content with
/// details about the current operation being performed.
class StageToolTip {
  bool _needsLayout = false;
  Size _paragraphSize;
  Paragraph _paragraph;
  String _text;
  String get text => _text;
  set text(String value) {
    if (_text == value) {
      return;
    }
    _text = value;

    _needsLayout = true;
  }

  Size get paragraphSize {
    if (_needsLayout) {
      layout();
    }
    return _paragraphSize;
  }

  void layout() {
    _needsLayout = false;
    final style = ParagraphStyle(
        textAlign: TextAlign.left, fontFamily: 'Roboto-Light', fontSize: 11);
    ParagraphBuilder builder = ParagraphBuilder(style)
      ..pushStyle(
        TextStyle(
          foreground: Paint()..color = RiveThemeData().colors.toolTipText,
        ),
      );
    builder.addText(text);
    _paragraph = builder.build();
    _paragraph.layout(const ParagraphConstraints(width: 400));
    List<TextBox> boxes = _paragraph.getBoxesForRange(0, text.length);
    _paragraphSize = boxes.isEmpty
        ? Size.zero
        : Size(boxes.last.right - boxes.first.left + 1,
            boxes.last.bottom - boxes.first.top + 1);
  }

  static const padding = Size(10, 6);
  void paint(Canvas canvas, Offset offset) {
    if (_needsLayout) {
      layout();
    }

    // Fix the position to full pixels.
    // Which will line this up better with the paragraph
    final left = offset.dx.floorToDouble();
    final top = offset.dy.floorToDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          top,
          _paragraphSize.width + padding.width * 2,
          _paragraphSize.height + padding.height * 2,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = RiveThemeData().colors.toolTip,
    );

    // Draw the tooltip text
    canvas.drawParagraph(
      _paragraph,
      Offset(left + padding.width, top + padding.height),
    );
  }
}
