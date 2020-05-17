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
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';

class VectorPenTool extends PenTool<Path> {
  static final VectorPenTool instance = VectorPenTool();

  PointsPath _creatingPath;

  @override
  bool activate(Stage stage) {
    if (super.activate(stage)) {
      stage.addSelectionHandler(_selectionHandler);
      stage.file.vertexEditor.creatingPath.addListener(_creatingPathChanged);
      return true;
    }
    return false;
  }

  void _creatingPathChanged() {
    
    _creatingPath = stage.file.vertexEditor.creatingPath.value;
    print("CREATING PATH CHANGED $_creatingPath");
  }

  @override
  void deactivate() {
    stage.removeSelectionHandler(_selectionHandler);
    stage.file.vertexEditor.creatingPath.removeListener(_creatingPathChanged);
    super.deactivate();
  }

  bool _selectionHandler(StageItem item) {
    print("SELECT $item $_creatingPath");
    if (item is StageVertex &&
        _creatingPath?.vertices?.first == item.component) {
      stage.file.vertexEditor.closePath(_creatingPath);
      _creatingPath = null;
    }
    return false;
  }

  @override
  void onEditingChanged(Iterable<Path> paths) {
    if (paths == null || !paths.contains(_creatingPath)) {
      _creatingPath = null;
    }
  }

  void _makeEditingPath(Artboard activeArtboard, Vec2D translation) {
    Shape shape;
    if (editing != null && editing.isNotEmpty) {
      shape = editing.first.shape;
    }

    if (shape == null) {
      shape = ShapeTool.makeShape(
          activeArtboard, _creatingPath = PointsPath()..name = 'Path')
        ..name = 'Shape';
      // We're making a new shape, so set the translation of the path to 0,0 and
      // the shape to the world translation.
      shape.x = translation[0];
      shape.y = translation[1];

      _creatingPath.calculateWorldTransform();
    } else {
      // We already had a shape, just add this path to it.
      _creatingPath = PointsPath()..name = 'Path';
      shape.appendChild(_creatingPath);

      // Make sure the internal world transform caches are up to date for
      // anything in this chain.
      _creatingPath.calculateWorldTransform();

      // Set the origin of the path to the local offset of the world translation
      // relative to the shape.
      Mat2D shapeWorldInverse = Mat2D();
      if (!Mat2D.invert(shapeWorldInverse, shape.worldTransform)) {
        Mat2D.identity(shapeWorldInverse);
        return;
      }

      var localTranslation =
          Vec2D.transformMat2D(Vec2D(), translation, shapeWorldInverse);
      _creatingPath.x = localTranslation[0];
      _creatingPath.y = localTranslation[1];
    }

    stage.file.vertexEditor.startCreatingPath(_creatingPath);

    // // Set the solo item as the path we just created which will trigger updating
    // // the editing components.
    // var solo = stage.soloItems;
    // solo ??= HashSet<StageItem>();
    // solo.add(_editingPath.stageItem);
    // stage.solo(solo);
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

    if (_creatingPath == null) {
      _makeEditingPath(activeArtboard, ghostPointWorld);
    }

    var localTranslation = Vec2D.transformMat2D(
        Vec2D(), worldMouse, _creatingPath.inverseWorldTransform);
    var vertex = StraightVertex()
      ..x = localTranslation[0]
      ..y = localTranslation[1]
      ..radius = 0;

    var file = _creatingPath.context;
    file.batchAdd(() {
      file.add(vertex);
      _creatingPath.appendChild(vertex);
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

  @override
  void draw(Canvas canvas) {
    canvas.save();
    canvas.transform(stage.viewTransform.mat4);
    for (final path in editing) {
      canvas.save();
      final origin = path.artboard.originWorld;
      canvas.translate(origin[0], origin[1]);
      canvas.transform(path.pathTransform?.mat4);
      canvas.drawPath(path.uiPath, StageItem.selectedPaint);
      canvas.restore();
    }
    canvas.restore();
    super.draw(canvas);
  }
}
