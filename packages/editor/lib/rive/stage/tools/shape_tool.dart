import 'dart:math';
import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/draggable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool_tip.dart';
import 'package:rive_editor/widgets/theme.dart';

const Map<EditMode, DraggingMode> editModeMap = {
  EditMode.altMode1: DraggingMode.symmetric
};

abstract class ShapeTool extends StageTool with DraggableTool {
  Vec2D _startWorldMouse;
  Vec2D _start = Vec2D(), _end = Vec2D(), _cursor = Vec2D();

  Shape shape(Vec2D worldMouse);
  ParametricPath get path;
  Shape _shape;
  ParametricPath _path;

  Artboard _currentArtboard;
  
  final StageToolTip _tip = StageToolTip();

  @override
  void startDrag(Iterable<StageItem> selection, Artboard activeArtboard,
      Vec2D worldMouse) {
    super.startDrag(selection, activeArtboard, worldMouse);
    assert(activeArtboard != null, 'Shape tool must have an active artboard.');
    _end = _start = null;
    // Create a Shape and place it at the world location.
    _startWorldMouse = Vec2D.clone(worldMouse);

    var file = activeArtboard.context;

    // Track the artboard we're using for this operation (in case it changes via
    // a shortcut or something while the drag operation is continuing).
    _currentArtboard = activeArtboard;

    _shape = shape(worldMouse);
    _path = path;

    file.batchAdd(() {
      var composer = PathComposer();
      var solidColor = SolidColor();
      var fill = Fill();

      file.add(_shape);
      file.add(fill);
      file.add(solidColor);
      file.add(composer);
      file.add(_path);

      // Let's build up the shape hierarchy:
      // Artboard
      // │
      // └─▶ Shape
      //       │
      //       ├─▶ Fill
      //       │     │
      //       │     └─▶ SolidColor
      //       │
      //       ├─▶ PathComposer
      //       │
      //       └─▶ Path
      _shape.appendChild(_path);
      _shape.appendChild(composer);
      _shape.appendChild(fill);
      fill.appendChild(solidColor);
      activeArtboard.appendChild(_shape);
    });
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    switch (editModeMap[editMode]) {
      case DraggingMode.symmetric:
        final maxChange = max(
          (_startWorldMouse[0] - worldMouse[0]).abs(),
          (_startWorldMouse[1] - worldMouse[1]).abs(),
        );
        final x1 = (_startWorldMouse[0] < worldMouse[0])
            ? _startWorldMouse[0]
            : _startWorldMouse[0] - maxChange;
        final y1 = (_startWorldMouse[1] < worldMouse[1])
            ? _startWorldMouse[1]
            : _startWorldMouse[1] - maxChange;
        _start = Vec2D.fromValues(
          x1,
          y1,
        );
        _end = Vec2D.fromValues(
          _start[0] + maxChange,
          _start[1] + maxChange,
        );
        break;
      default:
        _start = Vec2D.fromValues(
          min(_startWorldMouse[0], worldMouse[0]),
          min(_startWorldMouse[1], worldMouse[1]),
        );
        _end = Vec2D.fromValues(
          max(_startWorldMouse[0], worldMouse[0]),
          max(_startWorldMouse[1], worldMouse[1]),
        );
    }

    _cursor = Vec2D.clone(worldMouse);

    _shape.x = _start[0];
    _shape.y = _start[1];

    _path.width = _end[0] - _start[0];
    _path.height = _end[1] - _start[1];
    _path.x = _path.width / 2;
    _path.y = _path.height / 2;

    _tip.text =
        '${(_end[0] - _start[0]).round()}x${(_end[1] - _start[1]).round()}';
  }

  @override
  void endDrag() {
    // Intentionally empty, Stage captures journal entries for us when a drag
    // operation ends.
  }

  @override
  void draw(Canvas canvas) {
    // happens when we first start dragging.
    if (_start == null) {
      return;
    }
    // Get in screen space.
    var start = Vec2D.clone(stageWorldSpace(_currentArtboard, _start));
    var end = Vec2D.clone(stageWorldSpace(_currentArtboard, _end));
    var cursor = Vec2D.clone(stageWorldSpace(_currentArtboard, _cursor));
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
          ..color = RiveThemeData().colors.shapeBounds);

    _tip.paint(canvas, Offset(cursor[0]+10, cursor[1]+10));
  }

  @override
  void onEditModeChange() {
    // if the edit mode is changed lets just treat it as a fake drag.
    if (lastWorldMouse != null) {
      updateDrag(lastWorldMouse);
    }
  }
}
