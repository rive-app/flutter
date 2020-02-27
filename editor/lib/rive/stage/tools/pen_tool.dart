import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/user_path.dart';

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
  UserPath _path;

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
    return true;
  }

  @override
  void paint(Canvas canvas) {
    if (mousePosition != null) {
      var mp = Vec2D();
      Vec2D.transformMat2D(mp, mousePosition, stage.viewTransform);
      canvas.drawCircle(
          Offset(mp[0], mp[1]), 5, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    // TODO: implement mirrored vertex here.
  }

  @override
  void onClick(Vec2D worldMouse) {
    final rive = stage.rive;
    _modifyPath(worldMouse, rive);

    for (final v in _path.vertices) {
      print('PenTOOL V: $v');
    }
  }

  void _modifyPath(Vec2D vertexPos, Rive rive) {
    // Get the shape in which to the path lives
    _selectShape(rive, vertexPos);
    // Determine the coordinates to create a vertex based on the shape's
    // position in world space
    final localCoord = _coordinateMapper(_shape, vertexPos);
    // Create a new path if one isn't already being built
    if (_path == null) {
      _path = UserPath()
        ..name = 'My crazy _openPath'
        ..x = localCoord[0]
        ..y = localCoord[1]
        ..rotation = 0
        ..scaleX = 1
        ..scaleY = 1
        ..opacity = 1;
      // Add the path to the file and the shape
      _addToFile(rive.file.value, _path);
      _shape.appendChild(_path);
    }
    // Create the vertex and add it to the path
    _path.addVertex(localCoord[0], localCoord[1]);
    // Mark the shape as dirty so the stage redraws
    _shape.pathChanged(_path);
    _path.addDirt(ComponentDirt.path);
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
    // Add shape to the file; its stage equivalent is also created
    _addToFile(rive.file.value, _shape);
    // Add shape to the artboard
    _activeArtBoard(rive.file.value).appendChild(_shape);
  }

  void _addToFile(RiveFile file, Node node) {
    file.startAdd();
    file.add(node);
    file.cleanDirt();
    file.completeAdd();
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
