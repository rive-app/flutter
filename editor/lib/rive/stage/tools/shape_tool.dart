import 'dart:math';
import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';

import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/rive/theme.dart';

abstract class ShapeTool extends StageTool with DraggableTool {
  Vec2D _startWorldMouse;
  Vec2D _start = Vec2D(), _end = Vec2D(), _cursor = Vec2D();

  Shape shape(Vec2D worldMouse);
  ParametricPath get path;
  Shape _shape;
  ParametricPath _path;

  @override
  void startDrag(Iterable<StageItem> selection, Vec2D worldMouse) {
    super.startDrag(selection, worldMouse);
    _end = _start = null;
    // Create a Shape and place it at the world location.
    _startWorldMouse = Vec2D.clone(worldMouse);

    var file = stage.riveFile;
    var artboard = file.artboards.first;

    _shape = shape(worldMouse);
    _path = path;

    file.startAdd();
    file.add(_shape);
    file.add(_path);

    _shape.appendChild(_path);
    artboard.appendChild(_shape);

    file.cleanDirt();
    file.completeAdd();
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    _start = Vec2D.fromValues(min(_startWorldMouse[0], worldMouse[0]),
        min(_startWorldMouse[1], worldMouse[1]));
    _end = Vec2D.fromValues(max(_startWorldMouse[0], worldMouse[0]),
        max(_startWorldMouse[1], worldMouse[1]));

    _cursor = Vec2D.clone(worldMouse);

    _shape.x = _start[0];
    _shape.y = _start[1];

    _path.width = _end[0] - _start[0];
    _path.height = _end[1] - _start[1];
    _path.x = _path.width / 2;
    _path.y = _path.height / 2;
  }

  @override
  void endDrag() {
    stage.riveFile.captureJournalEntry();
  }

  @override
  void paint(Canvas canvas) {
    // happens when we first start dragging.
    if (_start == null) {
      return;
    }
    // Get in screen space.
    var start = Vec2D.clone(_start);
    var end = Vec2D.clone(_end);
    var cursor = Vec2D.clone(_cursor);
    Vec2D.transformMat2D(start, start, stage.viewTransform);
    Vec2D.transformMat2D(end, end, stage.viewTransform);
    Vec2D.transformMat2D(cursor, cursor, stage.viewTransform);
    // Get bounds in
    canvas.drawRect(
        Rect.fromLTRB(
          start[0],
          start[1],
          end[0],
          end[1],
        ),
        Paint()
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF000000));

    _paintToolTip(
        canvas,
        '${(_end[0] - _start[0]).round()}x${(_end[1] - _start[1]).round()}',
        cursor);
  }

  /// Paints a tool tip; currently used for the dargging xy co-ords
  void _paintToolTip(Canvas canvas, String text, Vec2D pos) {
    final style = ParagraphStyle(
        textAlign: TextAlign.left, fontFamily: 'Roboto-Light', fontSize: 11);
    ParagraphBuilder builder = ParagraphBuilder(style)
      ..pushStyle(
        TextStyle(
          foreground: Paint()..color = const Color(0xFFFFFFFF),
        ),
      );
    builder.addText(text);
    Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400));
    List<TextBox> boxes = paragraph.getBoxesForRange(0, text.length);
    var size = boxes.isEmpty
        ? Size.zero
        : Size(boxes.last.right - boxes.first.left + 1,
            boxes.last.bottom - boxes.first.top + 1);

    var offset = const Offset(10, 10);
    var padding = const Size(10, 6);

    // Fix the position to full pixels.
    // Which will line this up better with the paragraph
    var topLeft = (pos[0] + offset.dx).floor().toDouble();
    var topRight = (pos[1] + offset.dy).floor().toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          topLeft,
          topRight,
          size.width + padding.width * 2,
          size.height + padding.height * 2,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = RiveThemeData().colors.toolTip,
    );

    // Draw the tooltip text
    canvas.drawParagraph(
      paragraph,
      Offset(topLeft + padding.width, topRight + padding.height),
    );
  }
}
