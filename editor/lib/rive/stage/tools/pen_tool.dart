import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/rive_file.dart';
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
  void endDrag() {
    // TODO: implement mirrored vertex here.
  }

  @override
  bool activate(Stage stage) {
    super.activate(stage);
    // Reset the current selection.
    _path = null;
    _shape = null;
    return true;
  }

  @override
  void paint(Canvas canvas) {
    _paintMouse(canvas);
    // _paintVertices(canvas);
    // _paintEdges(canvas);
  }

  void _paintMouse(Canvas canvas) {
    if (mousePosition != null) {
      var mp = Vec2D();
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

  void _paintVertices(Canvas canvas) {
    if (_path != null) {
      final transform = Mat2D();
      Mat2D.multiply(transform, stage.viewTransform, _path.pathTransform);
      final pos = Vec2D();
      for (final vertex in _path.vertices) {
        Vec2D.transformMat2D(pos, vertex.translation, transform);
        _paintVertex(canvas, pos);
      }
    }
  }

  void _paintEdges(Canvas canvas) {
    if (_shape != null && _shape.pathComposer != null) {
      final uiPath = _shape.pathComposer.uiPath;
      canvas.save();
      canvas.transform(stage.viewTransform.mat4);
      // Once for the background.
      canvas.drawPath(
          uiPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0x19000000));
      // Once for the actual stroke.
      canvas.drawPath(
          uiPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFFFFFFFF));
    }
    canvas.restore();
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    // TODO: implement mirrored vertex here.
  }

  @override
  void onClick(Vec2D worldMouse) {
    final rive = stage.rive;
    _modifyPath(worldMouse, rive);
  }

  void _modifyPath(Vec2D vertexPos, Rive rive) {
    var file = rive.file.value;
    // Get the shape in which to the path lives
    _selectShape(rive, vertexPos);
    // Determine the coordinates to create a vertex based on the shape's
    // position in world space
    final localCoord = _coordinateMapper(_shape, vertexPos);
    // Create a new path if one isn't already being built
    if (_path == null) {
      _path = PointsPath()
        ..name = 'Pen Path'
        ..x = localCoord[0]
        ..y = localCoord[1]
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
      ..x = localCoord[0]
      ..y = localCoord[1];
    file.batchAdd(() {
      file.add(v);
      _path.addVertex(v);
    });
    // Mark the shape as dirty so the stage redraws
    _shape.pathChanged(_path);
  }

  /// Returns the first selected shape from the current set of
  /// selected items in the editor. Returns null if no shape is
  /// selected.
  void _selectShape(Rive rive, Vec2D coord) {
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
    var composer = PathComposer();
    // Add shape to the file; its stage equivalent is also created
    var file = rive.file.value;
    file.batchAdd(() {
      file.add(_shape);
      file.add(composer);
      _shape.appendChild(composer);
      // Add shape to the artboard
      _activeArtBoard(rive.file.value).appendChild(_shape);
    });
  }

  // TODO: need to track the active artboard
  Artboard _activeArtBoard(RiveFile file) => file.artboards.first;

  /// TODO: needs to take into account rotation, scale, etc; use matrix math
  Vec2D _coordinateMapper(Shape shape, Vec2D worldSpaceCoord) {
    // Do funky matrix math
    final x = worldSpaceCoord[0] - shape.x;
    final y = worldSpaceCoord[1] - shape.y;
    return Vec2D.fromValues(x, y);
  }
}
