import 'dart:math';
import 'dart:ui';

import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/path_composer.dart';
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

    file.batchAdd(() {
      var composer = PathComposer();
      file.add(_shape);
      file.add(composer);
      file.add(_path);

      _shape.appendChild(_path);
      _shape.appendChild(composer);
      artboard.appendChild(_shape);
    });
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
    var padding = const Size(10, 10);

    // Draw the tooltip background
    canvas.drawPath(
        _roundedRectPath(
          Vec2D.fromValues(
            pos[0] + offset.dx,
            pos[1] + offset.dy,
          ),
          size.width + padding.width * 2,
          size.height + padding.height * 2,
          5,
        ),
        Paint()..color = RiveThemeData().colors.toolTip);

    // Draw the tooltip text
    canvas.drawParagraph(
        paragraph,
        Offset(pos[0] + offset.dx + padding.width,
            pos[1] + offset.dy + padding.height));
  }
}

/// Draws a rounded rectangle whose top left corner is pos, using
/// the given width and height; radius defines the roundedness of each corner.
Path _roundedRectPath(Vec2D pos, double width, double height, double radius) =>
    Path()
      ..moveTo(pos[0] + width - radius, pos[1])
      ..arcTo(
          Rect.fromLTWH(
              pos[0] + width - (radius * 2), pos[1], radius * 2, radius * 2),
          pi * 3 / 2,
          pi / 2,
          false)
      ..lineTo(pos[0] + width, pos[1] + height - radius)
      ..arcTo(
          Rect.fromLTWH(pos[0] + width - (radius * 2),
              pos[1] + height - (radius * 2), radius * 2, radius * 2),
          0,
          pi / 2,
          false)
      ..lineTo(pos[0] + radius, pos[1] + height)
      ..arcTo(
          Rect.fromLTWH(
              pos[0], pos[1] + height - (radius * 2), radius * 2, radius * 2),
          pi / 2,
          pi / 2,
          false)
      ..lineTo(pos[0], pos[1] + radius)
      ..arcTo(Rect.fromLTWH(pos[0], pos[1], radius * 2, radius * 2), pi, pi / 2,
          false);
