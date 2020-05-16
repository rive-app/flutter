import 'package:flutter/widgets.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/simple_alert.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class VectorPenTool extends PenTool<Path> {
  static final VectorPenTool instance = VectorPenTool();

  PointsPath _editingPath;

  @override
  void onEditingChanged(Iterable<Path> paths) {
    if (paths == null || !paths.contains(_editingPath)) {
      _editingPath = null;
    }
  }

  void _makeEditingPath(Artboard activeArtboard, Vec2D translation) {
    // See if we have an editing shape already.
    // for(final item in editing) {
    //   if(item)
    // }

    Shape shape;
    if (editing != null && editing.isNotEmpty) {
      shape = editing.first.shape;
    }

    if (shape == null) {
      shape = ShapeTool.makeShape(
          activeArtboard, _editingPath = PointsPath()..name = 'Path')
        ..name = 'ShapyMcShapeFace';
      // We're making a new shape, so set the translation of the path to 0,0 and
      // the shape to the world translation.
      shape.x = translation[0];
      shape.y = translation[1];

      _editingPath.calculateWorldTransform();
    } else {
      // We already had a shape, just add this path to it.
      _editingPath = PointsPath()..name = 'Path';
      shape.appendChild(_editingPath);

      // Make sure the internal world transform caches are up to date for
      // anything in this chain.
      _editingPath.calculateWorldTransform();

      // Set the origin of the path to the local offset of the world translation
      // relative to the shape.
      Mat2D shapeWorldInverse = Mat2D();
      if (!Mat2D.invert(shapeWorldInverse, shape.worldTransform)) {
        Mat2D.identity(shapeWorldInverse);
        return;
      }

      var localTranslation =
          Vec2D.transformMat2D(Vec2D(), translation, shapeWorldInverse);
      _editingPath.x = localTranslation[0];
      _editingPath.y = localTranslation[1];
    }

    // Set the solo item as the shape we just created which will trigger
    // updating the editing components.
    stage.solo([shape.stageItem]);
  }

  @override
  void click(Artboard activeArtboard, Vec2D worldMouse) {
    if (!isShowingGhostPoint) {
      return;
    }

    if (activeArtboard == null) {
      stage.file.addAlert(
        SimpleAlert('Pen tool requires an artboard. Create one first.'),
      );
    }

    if (_editingPath == null) {
      _makeEditingPath(activeArtboard, ghostPointWorld);
    }

    var localTranslation = Vec2D.transformMat2D(
        Vec2D(), worldMouse, _editingPath.inverseWorldTransform);
    var vertex = StraightVertex()
      ..x = localTranslation[0]
      ..y = localTranslation[1]
      ..radius = 0;
    var file = _editingPath.context;
    file.batchAdd(() {
      file.add(vertex);
      _editingPath.appendChild(vertex);
    });

    file.captureJournalEntry();
  }

  @override
  Iterable<Path> getEditingComponents(Iterable<StageItem> solo) {
    // This gets called by the base pen tool to figure out what is currently
    // being edited. The vector pen tool edits paths, so we need to find which
    // paths are in the solo items.
    Set<Path> paths = {};

    // Solo could be null if we've just activated the tool with no selection. We
    // still want this tool to work in this case as the first click will create
    // a shape and path.
    if (solo != null) {
      for (final item in solo) {
        if (item is StagePath) {
          paths.add(item.component);
        }
      }
    }
    return paths;
  }
}
