import 'package:bezier/bezier.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/path_vertex_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/rive/vertex_editor.dart';
import 'package:vector_math/vector_math.dart';

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
    if (insertTarget != null) {
      stage.file.addAlert(
        SimpleAlert('TODO: subdivide :)'),
      );
      return;
    }
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
        PathVertexTranslateTransformer(),
      ];

  static const double snapIntersectionDistance = 10;

  @override
  PenToolInsertTarget computeInsertTarget(Vec2D worldMouse) {
    var editingPaths = vertexEditor.editingPaths;
    if (editingPaths == null) {
      return null;
    }

    double closestDistance = snapIntersectionDistance / stage.zoomLevel;
    PenToolInsertTarget result;

    for (final path in editingPaths) {
      var vertices = path.renderVertices;

      double closestPathDistance = double.maxFinite;
      Vec2D intersectionOnPath;
      Vec2D intersectionOnPathWorld;
      Vec2D intersection;

      var localMouse =
          Vec2D.transformMat2D(Vec2D(), worldMouse, path.inverseWorldTransform);
      for (int i = 0,
              l = path.isClosed ? vertices.length : vertices.length - 1,
              vl = vertices.length;
          i < l;
          i++) {
        var vertex = vertices[i];
        var nextVertex = vertices[(i + 1) % vl];

        Vec2D controlOut = vertex.coreType == CubicVertexBase.typeKey
            ? null
            : (vertex as CubicVertex).outPoint;
        Vec2D controlIn = nextVertex.coreType == CubicVertexBase.typeKey
            ? null
            : (nextVertex as CubicVertex).inPoint;
        if (controlIn == null && controlOut == null) {
          var v1 = vertex.translation;
          var v2 = nextVertex.translation;
          var t = Vec2D.onSegment(v1, v2, localMouse);
          if (t <= 0) {
            intersection = v1;
          } else if (t >= 1) {
            intersection = v2;
          } else {
            intersection = Vec2D.fromValues(
                v1[0] + (v2[0] - v1[0]) * t, v1[1] + (v2[1] - v1[1]) * t);
          }
          //localMouse vertex.translation, nextVertex.translation
        } else {
          controlOut ??= vertex.translation;
          controlIn ??= nextVertex.translation;
          var cubic = CubicBezier([
            Vector2(vertex.translation[0], vertex.translation[1]),
            Vector2(controlOut[0], controlOut[1]),
            Vector2(controlIn[0], controlIn[1]),
            Vector2(nextVertex.translation[0], nextVertex.translation[1])
          ]);
          // TODO: if a designer complains about the cubic being too coarse, we
          // may want to compute the screen length of the cubic and change the
          // iterations passed to nearestTValue.
          double t = cubic.nearestTValue(Vector2(localMouse[0], localMouse[1]));
          var point = cubic.pointAt(t);
          intersection = Vec2D.fromValues(point.x, point.y);
        }

        // Compute distance in world space in case multiple paths are edited
        // and have different world transform. TODO: if connected bones use
        // closest as it'll be already in world space
        var intersectionWorld =
            Vec2D.transformMat2D(Vec2D(), intersection, path.worldTransform);

        double distance = Vec2D.distance(worldMouse, intersectionWorld);
        if (distance < closestPathDistance) {
          closestPathDistance = distance;
          intersectionOnPath = intersection;
          intersectionOnPathWorld = intersectionWorld;
        }
      }

      if (closestPathDistance < closestDistance) {
        result = PenToolInsertTarget(
          translation: intersectionOnPath,
          worldTranslation: intersectionOnPathWorld,
        );
      }
    }

    return result;
  }
}
