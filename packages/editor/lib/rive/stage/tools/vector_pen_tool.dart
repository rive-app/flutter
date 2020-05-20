import 'package:flutter/widgets.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/vertex_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/rive/vertex_editor.dart';

class VectorPenTool extends PenTool<Path> with TransformingTool {
  static final VectorPenTool instance = VectorPenTool();

  PointsPath _makeEditingPath(Artboard activeArtboard, Vec2D translation) {
    Shape shape;

    if (vertexEditor.editingPaths != null &&
        vertexEditor.editingPaths.isNotEmpty) {
      shape = vertexEditor.editingPaths.first.shape;
    }

    var path = PointsPath()..name = 'Path';
    if (shape == null) {
      shape = ShapeTool.makeShape(activeArtboard, path)..name = 'Shape';
      // We're making a new shape, so set the translation of the path to 0,0 and
      // the shape to the world translation.
      shape.x = translation[0];
      shape.y = translation[1];

      path.calculateWorldTransform();
    } else {
      var core = shape.context;
      core.batchAdd(() {
        // Make sure the path is registered with core.
        core.add(path);

        // We already had a shape, just add this path to it.
        shape.appendChild(path);

        // Set the origin of the path to the local offset of the world
        // translation relative to the shape.
        Mat2D shapeWorldInverse = Mat2D();
        if (!Mat2D.invert(shapeWorldInverse, shape.worldTransform)) {
          Mat2D.identity(shapeWorldInverse);
        }

        var localTranslation =
            Vec2D.transformMat2D(Vec2D(), translation, shapeWorldInverse);
        path.x = localTranslation[0];
        path.y = localTranslation[1];

        // Make sure the internal world transform caches are up to date for
        // anything in this chain.
        path.calculateWorldTransform();
      });
    }

    // Mark the path as being created, this allows the vertex editor to catch
    // the core editor property change and update its internal state.
    path.editingMode = PointsPathEditMode.creating;

    return path;
  }

  VertexEditor get vertexEditor => stage.file.vertexEditor;

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

    var path = vertexEditor.creatingPath.value ??
        _makeEditingPath(activeArtboard, ghostPointWorld);

    var localTranslation =
        Vec2D.transformMat2D(Vec2D(), worldMouse, path.inverseWorldTransform);
    var vertex = StraightVertex()
      ..x = localTranslation[0]
      ..y = localTranslation[1]
      ..radius = 0;

    var file = path.context;
    file.batchAdd(() {
      file.add(vertex);
      path.appendChild(vertex);
    });
    file.captureJournalEntry();
  }

  @override
  void draw(Canvas canvas) {
    var editingPaths = vertexEditor.editingPaths;
    if (editingPaths != null) {
      canvas.save();
      canvas.transform(stage.viewTransform.mat4);
      for (final path in editingPaths) {
        canvas.save();
        final origin = path.artboard.originWorld;
        canvas.translate(origin[0], origin[1]);
        canvas.transform(path.pathTransform?.mat4);
        canvas.drawPath(path.uiPath, StageItem.selectedPaint);

        // Draw line to ghost point from last point.
        if (path.editingMode == PointsPathEditMode.creating &&
            path.vertices.isNotEmpty) {
          Offset targetOffset;
          // Draw line to next point (note this should curve if last point is a
          // cubic).
          var lastVertex = path.vertices.last;
          if (ghostPointWorld != null) {
            // get ghost point into local
            var inversePath = Mat2D();
            if (!Mat2D.invert(inversePath, path.pathTransform)) {
              Mat2D.identity(inversePath);
            }
            var ghostLocal =
                Vec2D.transformMat2D(Vec2D(), ghostPointWorld, inversePath);
            targetOffset = Offset(ghostLocal[0], ghostLocal[1]);
          } else if (stage.hoverItem == path.vertices.first.stageItem) {
            var target = path.vertices.first;
            // closing the loop
            targetOffset = Offset(target.x, target.y);
          }

          if (targetOffset != null) {
            canvas.drawLine(Offset(lastVertex.x, lastVertex.y), targetOffset,
                StageItem.selectedPaint);
          }
        }
        canvas.restore();
      }
      canvas.restore();
    }
    super.draw(canvas);
  }

  @override
  List<StageTransformer> get transformers => [
        VertexTranslateTransformer(),
      ];
}
