import 'package:bezier/bezier.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/path_vertex.dart';
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
      if (!_split()) {
        stage.file.addAlert(
          SimpleAlert('TODO: subdivide :)'),
        );
      }
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
      Vec2D intersection;

      PenToolInsertTarget pathResult;

      var localMouse =
          Vec2D.transformMat2D(Vec2D(), worldMouse, path.inverseWorldTransform);
      for (int i = 0,
              l = path.isClosed ? vertices.length : vertices.length - 1,
              vl = vertices.length;
          i < l;
          i++) {
        var vertex = vertices[i];
        var nextVertex = vertices[(i + 1) % vl];
        CubicBezier cubicBezier;

        Vec2D controlOut = vertex.coreType != CubicVertexBase.typeKey
            ? null
            : (vertex as CubicVertex).outPoint;
        Vec2D controlIn = nextVertex.coreType != CubicVertexBase.typeKey
            ? null
            : (nextVertex as CubicVertex).inPoint;

        // There are no cubic control points, this is just a linear edge.
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
          // Either in, out, or both are cubic control points.
          controlOut ??= vertex.translation;
          controlIn ??= nextVertex.translation;
          cubicBezier = CubicBezier([
            Vector2(vertex.translation[0], vertex.translation[1]),
            Vector2(controlOut[0], controlOut[1]),
            Vector2(controlIn[0], controlIn[1]),
            Vector2(nextVertex.translation[0], nextVertex.translation[1])
          ]);
          // TODO: if a designer complains about the cubic being too coarse, we
          // may want to compute the screen length of the cubic and change the
          // iterations passed to nearestTValue.
          double t =
              cubicBezier.nearestTValue(Vector2(localMouse[0], localMouse[1]));
          var point = cubicBezier.pointAt(t);
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
          pathResult = PenToolInsertTarget(
            path: path,
            translation: intersection,
            worldTranslation: intersectionWorld,
            from: vertex,
            to: nextVertex,
            cubic: cubicBezier,
          );
        }
      }

      if (closestPathDistance < closestDistance) {
        result = pathResult;
      }
    }

    return result;
  }

  bool _split() {
    var path = insertTarget.path;
    var file = path.context;

    if (insertTarget.cubic == null) {
      var from = insertTarget.from.coreVertex;

      // If our from point is the last point in the list, append to the end of
      // the fractional indexed list, otherwise compute the inbetween fractional
      // value of from and to.
      var index = path.vertices.last == from
          ? FractionalIndex.between(
              from.childOrder, const FractionalIndex.max())
          : FractionalIndex.between(
              from.childOrder, insertTarget.to.coreVertex.childOrder);

      var vertex = StraightVertex()
        ..x = insertTarget.translation[0]
        ..y = insertTarget.translation[1]
        ..radius = 0
        ..childOrder = index;

      file.batchAdd(() {
        file.add(vertex);
        vertex.parent = path;
      });
      file.captureJournalEntry();
      return true;
    }

    bool isNextCorner = insertTarget.to.isCornerRadius;
    bool isPrevCorner = insertTarget.from.isCornerRadius;
    // Both points are corner radiuses?
    if (isNextCorner && isPrevCorner) {
      var from = insertTarget.from as CubicVertex;
      var to = insertTarget.to as CubicVertex;
      // Both share the same original core vertex? Then they're the same
      // corner...
      if (to.coreVertex == from.coreVertex) {
        var vertexIndex = path.vertices.indexOf(to.coreVertex);
        FractionalIndex before = vertexIndex == 0
            ? const FractionalIndex.min()
            : path.vertices[vertexIndex - 1].childOrder;
        FractionalIndex after = vertexIndex + 1 >= path.vertices.length
            ? const FractionalIndex.max()
            : path.vertices[vertexIndex + 1].childOrder;

        file.batchAdd(() {
          // Remove old corner point...
          from.coreVertex.remove();

          // Add the corner cubics as real core points.
          var vertexA = CubicVertex()
            ..controlType = VertexControlType.detached
            ..x = from.translation[0]
            ..y = from.translation[1]
            ..inX = from.inX
            ..inY = from.inY
            ..outX = from.outX
            ..outY = from.outY
            ..childOrder = FractionalIndex.between(before, after);

          var vertexB = CubicVertex()
            ..controlType = VertexControlType.detached
            ..x = to.translation[0]
            ..y = to.translation[1]
            ..inX = to.inX
            ..inY = to.inY
            ..outX = to.outX
            ..outY = to.outY
            ..childOrder = FractionalIndex.between(vertexA.childOrder, after);

          file.add(vertexA);
          vertexA.parent = path;
          file.add(vertexB);
          vertexB.parent = path;
        });
      }
    }
    file.captureJournalEntry();

    return false;
  }
}
