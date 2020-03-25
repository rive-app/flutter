import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/moveable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
// This will import and extension that give shapes access to their stage shapes
// import 'package:rive_editor/rive/stage/stage_item.dart' show StageItemComponent;

class PenTool extends StageTool with MoveableTool, ClickableTool {
  static final PenTool instance = PenTool._();

  PenTool._();

  // Open path used to create the shape
  PointsPath _path;

  // Shape in which the open payth exists
  Shape _shape;

  @override
  String get icon => 'tool-pen';

  @override
  bool activate(Stage stage) {
    super.activate(stage);
    // Reset the current selection.
    _path = null;
    _shape = null;
    return true;
  }

  @override
  void draw(Canvas canvas) {
    // Paint dot under the mouse cursor.
    if (mousePosition != null) {
      final mp = Vec2D();
      Vec2D.transformMat2D(mp, mousePosition, stage.viewTransform);
      _paintVertex(canvas, mp);
    }
  }

  void _paintVertex(Canvas canvas, Vec2D position) {
    // Draw twice: once for the background stroke, and a second time for
    // the foreground
    canvas.drawCircle(Offset(position[0], position[1]), 4.5,
        Paint()..color = const Color(0x19000000));
    canvas.drawCircle(Offset(position[0], position[1]), 3.5,
        Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  void onClick(Artboard activeArtboard, Vec2D worldMouse) {
    final rive = stage.rive;
    _modifyPath(activeArtboard, worldMouse, rive);
  }

  void _modifyPath(Artboard activeArtboard, Vec2D worldMouse, Rive rive) {
    final file = rive.file.value;
    // Get the shape in which to the path lives
    _selectShape(activeArtboard, rive, worldMouse);

    // Create a new path if one isn't already being built
    if (_path == null) {
      _path = PointsPath()
        ..name = 'Pen Path'
        ..x = worldMouse[0]
        ..y = worldMouse[1]
        ..rotation = 0
        ..scaleX = 1
        ..scaleY = 1
        ..opacity = 1;
      // Add the path to the file and the shape
      file.batchAdd(() {
        file.add(_path);
        _shape.appendChild(_path);
        _shape.addPath(_path);
      });
      _path.calculateWorldTransform();
    }
    final v = StraightVertex()
      ..name = 'Pen Vertex'
      ..x = worldMouse[0]
      ..y = worldMouse[1];
    file.batchAdd(() {
      file.add(v);
      _path.addVertex(v);
    });
    // Mark the shape as dirty so the stage redraws
    _shape.pathChanged(_path);
    // Propagate the changes here.
    file.captureJournalEntry();
  }

  /// Returns the first selected shape from the current set of
  /// selected items in the editor. Returns null if no shape is
  /// selected.
  void _selectShape(Artboard activeArtboard, Rive rive, Vec2D coord) {
    // If there's already a selected shape, do nothing
    if (_shape != null) {
      return;
    }
    // Otherwise, check if there's a selected shape in the stage
    final firstSelectedStageShape = rive.selection.items.firstWhere(
      (i) => i is StageShape,
      orElse: () => null,
    );
    if (firstSelectedStageShape != null &&
        firstSelectedStageShape is StageShape) {
      _shape = firstSelectedStageShape.component;
      return;
    }
    // No selected shape, create a new one and add it to the file
    _shape = Shape()
      ..name = 'New Shape'
      ..x = coord[0]
      ..y = coord[1]
      ..rotation = 0
      ..scaleX = 1
      ..scaleY = 1
      ..opacity = 1;
    final composer = PathComposer();
    // Add shape to the file; its stage equivalent is also created
    final file = rive.file.value;
    file.batchAdd(() {
      file.add(_shape);
      file.add(composer);
      _shape.appendChild(composer);
      // Add shape to the artboard
      activeArtboard.appendChild(_shape);
    });
  }
}
