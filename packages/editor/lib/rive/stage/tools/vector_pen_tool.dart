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
import 'package:rive_editor/math_extensions.dart';

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
        double cubicSplitT;

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
          cubicSplitT =
              cubicBezier.nearestTValue(Vector2(localMouse[0], localMouse[1]));
          var point = cubicBezier.pointAt(cubicSplitT);
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
            cubicSplitT: cubicSplitT,
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
    var target = insertTarget;
    var path = target.path;
    var vertices = path.vertices;
    var file = path.context;

    if (target.cubic == null) {
      var from = target.from.coreVertex;

      var vertex = StraightVertex()
        ..x = target.translation[0]
        ..y = target.translation[1]
        ..radius = 0
        ..childOrder = _fractionalIndexAt(vertices, vertices.indexOf(from) + 1);

      file.batchAdd(() {
        file.add(vertex);
        vertex.parent = path;
      });
      file.captureJournalEntry();
      return true;
    }

    int insertionIndex;
    bool isNextCorner = target.to.isCornerRadius;
    bool isPrevCorner = insertTarget.from.isCornerRadius;
    // Both points are corner radiuses?
    if (isNextCorner && isPrevCorner) {
      var from = insertTarget.from as CubicVertex;
      var to = insertTarget.to as CubicVertex;
      // Both share the same original core vertex? Then they're the same
      // corner...
      if (to.coreVertex == from.coreVertex) {
        var vertexIndex = vertices.indexOf(to.coreVertex);
        FractionalIndex before = vertexIndex == 0
            ? const FractionalIndex.min()
            : vertices[vertexIndex - 1].childOrder;
        FractionalIndex after = vertexIndex + 1 >= vertices.length
            ? const FractionalIndex.max()
            : vertices[vertexIndex + 1].childOrder;

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

          // Update our insert target to include the new vertices.
          target = target.copyWith(
            from: vertexA,
            to: vertexB,
          );
        });

        // We replaced both of them with new core points so neither are
        // corners anymore.
        isNextCorner = isPrevCorner = false;
      }
      insertionIndex = vertices.indexOf(target.from.coreVertex) + 1;
    } else if (isNextCorner) {
      insertionIndex = vertices.indexOf(target.from.coreVertex) + 1;
    } else if (isPrevCorner) {
      insertionIndex = vertices.indexOf(target.to.coreVertex);
    } else {
      insertionIndex = vertices.indexOf(target.from.coreVertex) + 1;
    }

    var leftSplit = target.cubic.leftSubcurveAt(target.cubicSplitT);
    var rightSplit = target.cubic.rightSubcurveAt(target.cubicSplitT);

    // Patch up previous handles they belong to a cubic.
    if (!isPrevCorner) {
      var prev = target.from.coreVertex;
      if (prev is CubicVertex) {
        prev.controlType = VertexControlType.detached;
        // TODO: accomodate for bones: https://github.com/2d-inc/2dimensions/blob/fc5a0128cb2419925f52e83e231192c645f58075/source/client/source/editors/flare/engine/Stage/Tools/VectorPenTool.jsx#L321
        prev.outPoint = leftSplit.points[1].toVec2D();
      }
    }

    // Patch up next handles if they belong to a cubic.
    if (!isNextCorner) {
      var pointIndex = vertices.indexOf(target.from.coreVertex);
      var next = vertices[(pointIndex + 1) % vertices.length];
      if (next is CubicVertex) {
        next.controlType = VertexControlType.detached;
        // TODO: fix bones: https://github.com/2d-inc/2dimensions/blob/fc5a0128cb2419925f52e83e231192c645f58075/source/client/source/editors/flare/engine/Stage/Tools/VectorPenTool.jsx#L338
        next.inPoint = rightSplit.points[2].toVec2D();
      }
    }

    file.batchAdd(() {
      var vertex = CubicVertex()
        ..controlType = VertexControlType.detached
        ..x = leftSplit.points[3].x
        ..y = leftSplit.points[3].y
        ..inX = leftSplit.points[2].x
        ..inY = leftSplit.points[2].y
        ..outX = rightSplit.points[1].x
        ..outY = rightSplit.points[1].y
        ..childOrder = _fractionalIndexAt(vertices, insertionIndex);

      file.add(vertex);
      vertex.parent = path;
    });

    // remove duplicates...
    bool replaced;
    do {
      replaced = false;
      var length = vertices.length;
      for (var i = 1, limit = path.isClosed ? length + 1 : length;
          i < limit;
          i++) {
        var pointA = vertices[(i - 1) % length];
        var pointB = vertices[i % length];

        if (Vec2D.approximatelyEqual(pointA.translation, pointB.translation)) {
          pointB.remove();
          if (pointA is CubicVertex && pointB is CubicVertex) {
            pointA.outPoint = pointB.outPoint;
          }
          replaced = true;
          break;
        }
      }
    } while (replaced);

    // capture undo/redo
    file.captureJournalEntry();

    return false;
  }
}

FractionalIndex _fractionalIndexAt(List<PathVertex> vertices, int index) {
  assert(index != -1);
  if (index >= vertices.length) {
    return FractionalIndex.between(
        vertices.last.childOrder, const FractionalIndex.max());
  } else if (index == 0) {
    return FractionalIndex.between(
        const FractionalIndex.min(), vertices.first.childOrder);
  }

  return FractionalIndex.between(
      vertices[index - 1].childOrder, vertices[index].childOrder);
}
