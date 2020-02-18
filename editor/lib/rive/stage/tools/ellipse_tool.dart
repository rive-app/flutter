import 'dart:math';
import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

import 'stage_tool.dart';

class EllipseTool extends StageTool {
  Vec2D _startWorldMouse;
  Ellipse _ellipse;
  Shape _shape;
  @override
  void startDrag(Iterable<StageItem> selection, Vec2D worldMouse) {
    super.startDrag(selection, worldMouse);
    _end = _start = null;
    // Create a Shape and place it at the world location.
    _startWorldMouse = Vec2D.clone(worldMouse);
    _shape = Shape()
      ..name = 'Ellipse'
      ..x = worldMouse[0]
      ..y = worldMouse[1]
      ..rotation = 0
      ..scaleX = 1
      ..scaleY = 1
      ..opacity = 1;
    _ellipse = Ellipse()
      ..name = 'Ellipse Path'
      ..x = 0
      ..y = 0
      ..rotation = 0
      ..scaleX = 1
      ..scaleY = 1
      ..opacity = 1
      ..width = 0
      ..height = 0;

    var file = stage.riveFile;
    var artboard = file.artboards.first;
    
    file.startAdd();
    file.add(_shape);
    file.add(_ellipse);

    _shape.appendChild(_ellipse);
    artboard.appendChild(_shape);

    file.cleanDirt();
    file.completeAdd();
  }

  @override
  void endDrag() {
    stage.riveFile.captureJournalEntry();
  }

  Vec2D _start = Vec2D(), _end = Vec2D(), _cursor = Vec2D();

  @override
  void updateDrag(Vec2D worldMouse) {
    _end = _start = Vec2D.fromValues(min(_startWorldMouse[0], worldMouse[0]),
        min(_startWorldMouse[1], worldMouse[1]));
    _end = Vec2D.fromValues(max(_startWorldMouse[0], worldMouse[0]),
        max(_startWorldMouse[1], worldMouse[1]));

    _cursor = Vec2D.clone(worldMouse);

    _shape.x = _start[0];
    _shape.y = _start[1];

    _ellipse.width = _end[0] - _start[0];
    _ellipse.height = _end[1] - _start[1];
    _ellipse.x = _ellipse.width / 2;
    _ellipse.y = _ellipse.height / 2;
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

    String text =
        '${(_end[0] - _start[0]).round()}x${(_end[1] - _start[1]).round()}';

    final style = ParagraphStyle(
        textAlign: TextAlign.left, fontFamily: 'Roboto-Regular', fontSize: 13);
    ParagraphBuilder builder = ParagraphBuilder(style)
      ..pushStyle(
        TextStyle(foreground: Paint()..color = const Color(0xFFFFFFFF)),
      );
    builder.addText(text);
    Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400));
    List<TextBox> boxes = paragraph.getBoxesForRange(0, text.length);
    var size = boxes.isEmpty
        ? Size.zero
        : Size(boxes.last.right - boxes.first.left,
            boxes.last.bottom - boxes.first.top);

    var offset = const Offset(10, 10);
    var padding = const Size(10, 5);
    canvas.drawRect(
        Rect.fromLTWH(
          cursor[0] + offset.dx,
          cursor[1] + offset.dy,
          size.width + padding.width * 2,
          size.height + padding.height * 2,
        ),
        Paint()..color = const Color(0xFF000000));
    canvas.drawParagraph(
        paragraph,
        Offset(cursor[0] + offset.dx + padding.width,
            cursor[1] + offset.dy + padding.height));
  }

  @override
  String get icon => 'tool-ellipse';

  static final EllipseTool instance = EllipseTool();
}
