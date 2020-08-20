import 'dart:math';
import 'dart:ui' as ui;

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
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/stage/items/stage_path_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/path_vertex_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/rive/vertex_editor.dart';
import 'package:vector_math/vector_math.dart';
import 'package:rive_editor/math_extensions.dart';
import 'package:utilities/restorer.dart';

class VectorPenTool extends PenTool<Path> with TransformingTool {
  static final VectorPenTool instance = VectorPenTool();

  PointsPath _makeEditingPath(Artboard activeArtboard, Vec2D translation) {
    Shape shape;

    if (vertexEditor.editingPaths != null &&
        vertexEditor.editingPaths.isNotEmpty) {
      shape = vertexEditor.editingPaths.first.shape;
    }

    if (shape == null) {
      // No shape, see if there's a single selection and whether it's a path.
      // Use the shape if so. #893
      var selection = stage.file.selection.items.length == 1
          ? stage.file.selection.items.first
          : null;
      if (selection is StageItem && selection.component is Path) {
        var path = selection.component as Path;
        shape = path.shape;
      }
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
        core.addObject(path);

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

  StraightVertex _clickCreatedVertex;
  Restorer _restoreAutoKey;

  @override
  void click(Artboard activeArtboard, Vec2D worldMouse) {
    _clickCreatedVertex = null;
    if (insertTarget != null) {
      if (!_split()) {
        stage.file.addAlert(
          SimpleAlert('Failed to subdivide.'),
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

    var localTranslation = Vec2D.transformMat2D(
      Vec2D(),
      // if there's a ghost point, use that as the vertex position, as the axis
      // might be locked
      ghostPointWorld ?? worldMouse,
      path.inverseWorldTransform,
    );
    var vertex = _clickCreatedVertex = StraightVertex()
      ..x = localTranslation[0]
      ..y = localTranslation[1]
      ..radius = 0;

    var file = path.context;
    _restoreAutoKey = file.suppressAutoKey();
    file.batchAdd(() {
      file.addObject(vertex);
      path.appendChild(vertex);
    });
  }

  @override
  bool endClick() {
    _restoreAutoKey?.restore();

    // capture when click completes.
    return true;
  }

  static final Paint contourShadow = Paint()
    ..style = PaintingStyle.stroke
    // Stroke is 3 so 1.5 sticks out when we draw fill over it.
    ..strokeWidth = 3
    ..color = const Color(0x26000000);

  static final Paint contourLine = Paint()
    ..style = PaintingStyle.stroke
    // Stroke is 3 so 1.5 sticks out when we draw fill over it.
    ..strokeWidth = 1
    ..color = const Color(0x80FFFFFF);

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    contourShadow.strokeWidth = StageItem.selectedPaint.strokeWidth * 3;
    contourLine.strokeWidth = StageItem.selectedPaint.strokeWidth;
    var editingPaths = vertexEditor.editingPaths;
    if (editingPaths != null) {
      canvas.save();
      canvas.transform(stage.viewTransform.mat4);
      for (final path in editingPaths) {
        canvas.save();
        final origin = path.artboard.originWorld;
        canvas.translate(origin[0], origin[1]);
        canvas.transform(path.pathTransform?.mat4);
        canvas.drawPath(path.uiPath, contourShadow);
        canvas.drawPath(path.uiPath, contourLine);

        // Draw line to ghost point from last point.
        if (path.editingMode == PointsPathEditMode.creating &&
            path.vertices.isNotEmpty &&
            // Don't draw line if we're about to split the curve...
            insertTarget == null) {
          Offset targetOffset;
          PathVertex closeTarget;
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
            closeTarget = path.vertices.first;
            // closing the loop
            targetOffset = Offset(closeTarget.x, closeTarget.y);
          }

          if (targetOffset != null) {
            if (lastVertex is CubicVertex) {
              var path = ui.Path();
              path.moveTo(lastVertex.x, lastVertex.y);
              if (closeTarget is CubicVertex) {
                path.cubicTo(
                    lastVertex.outPoint[0],
                    lastVertex.outPoint[1],
                    closeTarget.inPoint[0],
                    closeTarget.inPoint[1],
                    targetOffset.dx,
                    targetOffset.dy);
              } else {
                path.quadraticBezierTo(lastVertex.outPoint[0],
                    lastVertex.outPoint[1], targetOffset.dx, targetOffset.dy);
              }
              canvas.drawPath(path, StageItem.selectedPaint);
            } else {
              canvas.drawLine(Offset(lastVertex.x, lastVertex.y), targetOffset,
                  StageItem.selectedPaint);
            }
          }
        }
        canvas.restore();
      }
      canvas.restore();
    }
    super.draw(canvas, drawPass);
    drawTransformers(canvas);
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

        Vec2D controlOut = vertex is CubicVertex ? vertex.outPoint : null;
        Vec2D controlIn = nextVertex is CubicVertex ? nextVertex.inPoint : null;

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
    // Copy it in case we make changes to it (this allows indexOf to return the
    // original index in the list before items were removed/swapped).
    var vertices = path.vertices.toList(growable: false);
    var file = path.context;
    var autoKeySuppression = file.suppressAutoKey();

    if (target.cubic == null) {
      var from = target.from.coreVertex;

      var vertex = StraightVertex()
        ..x = target.translation[0]
        ..y = target.translation[1]
        ..radius = 0
        ..childOrder = _fractionalIndexAt(vertices, vertices.indexOf(from) + 1);

      file.batchAdd(() {
        file.addObject(vertex);
        vertex.parent = path;
      });
      file.captureJournalEntry();
      autoKeySuppression.restore();
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
          var vertexA = CubicDetachedVertex.fromValues(
            x: from.translation[0],
            y: from.translation[1],
            inX: from.inPoint[0],
            inY: from.inPoint[1],
            outX: from.outPoint[0],
            outY: from.outPoint[1],
          )..childOrder = FractionalIndex.between(before, after);

          var vertexB = CubicDetachedVertex.fromValues(
            x: to.translation[0],
            y: to.translation[1],
            inX: to.inPoint[0],
            inY: to.inPoint[1],
            outX: to.outPoint[0],
            outY: to.outPoint[1],
          )..childOrder = FractionalIndex.between(vertexA.childOrder, after);

          file.addObject(vertexA);
          vertexA.parent = path;
          file.addObject(vertexB);
          vertexB.parent = path;

          // Update our insert target to include the new vertices.
          target = target.copyWith(
            from: vertexA,
            to: vertexB,
          );
        });

        // Vertices have changed, let's recompute the list so further indexOf
        // operations give us the right value.
        vertices = path.vertices.toList(growable: false);

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

    file.batchAdd(() {
      // Patch up previous handles they belong to a cubic.
      if (!isPrevCorner) {
        var prev = target.from.coreVertex;
        if (prev is CubicVertex) {
          var newVertex = CubicDetachedVertex.fromValues(
            x: prev.x,
            y: prev.y,
            inPoint: prev.inPoint,
            outPoint: prev.outPoint,
          );
          prev.replaceWith(newVertex);
          // TODO: accomodate for bones: https://github.com/2d-inc/2dimensions/blob/fc5a0128cb2419925f52e83e231192c645f58075/source/client/source/editors/flare/engine/Stage/Tools/VectorPenTool.jsx#L321
          newVertex.outPoint = leftSplit.points[1].toVec2D();
        }
      }

      // Patch up next handles if they belong to a cubic.
      if (!isNextCorner) {
        var pointIndex = vertices.indexOf(target.from.coreVertex);
        var next = vertices[(pointIndex + 1) % vertices.length];
        if (next is CubicVertex) {
          var newVertex = CubicDetachedVertex.fromValues(
            x: next.x,
            y: next.y,
            inPoint: next.inPoint,
            outPoint: next.outPoint,
          );
          next.replaceWith(newVertex);
          // TODO: fix bones: https://github.com/2d-inc/2dimensions/blob/fc5a0128cb2419925f52e83e231192c645f58075/source/client/source/editors/flare/engine/Stage/Tools/VectorPenTool.jsx#L338
          newVertex.inPoint = rightSplit.points[2].toVec2D();
        }
      }

      var vertex = CubicDetachedVertex.fromValues(
        x: leftSplit.points[3].x,
        y: leftSplit.points[3].y,
        inX: leftSplit.points[2].x,
        inY: leftSplit.points[2].y,
        outX: rightSplit.points[1].x,
        outY: rightSplit.points[1].y,
      )..childOrder = _fractionalIndexAt(vertices, insertionIndex);
      file.addObject(vertex);

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
    autoKeySuppression.restore();

    return true;
  }

  @override
  void startTransformers(
    Iterable<StageItem> selection,
    Vec2D worldMouse,
  ) {
    if (_clickCreatedVertex != null) {
      // Make sure the solo items have been updated.
      vertexEditor.ensureSoloSync();

      var vertex = _clickCreatedVertex;
      var artboardMouse = mouseWorldSpace(vertex.artboard, worldMouse);
      _clickCreatedVertex = null;
      var path = vertex.path;
      var localTranslation = Vec2D.transformMat2D(
          Vec2D(), artboardMouse, path.inverseWorldTransform);
      vertex.remove();

      var cubicVertex = CubicMirroredVertex()
        ..x = vertex.x
        ..y = vertex.y
        ..outPoint = localTranslation
        ..childOrder = vertex.childOrder;

      var file = path.context;
      file.batchAdd(() {
        file.addObject(cubicVertex);
        path.appendChild(cubicVertex);
      });

      // Force a drag on the out with 0,0 delta to update the in.
      var controlOut = (cubicVertex.stageItem as StagePathVertex).controlOut;
      var transformer = PathVertexTranslateTransformer();
      var details = DragTransformDetails(vertex.artboard, Vec2D());
      transformer.init({controlOut}, details);
      transformer.advance(details);
      stage.file.select(controlOut);
    }
    super.startTransformers(selection, worldMouse);
  }

  @override
  bool canSelect(StageItem item) => item is StageVertex;

  @override
  bool mouseMove(Artboard activeArtboard, Vec2D worldMouse) {
    // See if we're in path edit mode, and there's a previous vertex. If there
    // is, get the previous vertex point and the mouse in local space, and
    // calculate the sector in which the mouse currently sits
    lockAxis = null;
    final editingPaths = vertexEditor.editingPaths;

    if (editingPaths != null &&
        editingPaths.isNotEmpty &&
        ghostPointWorld != null) {
      // Current editing path is the last in the list
      PointsPath path;
      for (final p in editingPaths) {
        if (p.editingMode == PointsPathEditMode.creating) {
          path = p;
          break;
        }
      }

      if (path != null &&
          (path.editingMode == PointsPathEditMode.creating ||
              path.editingMode == PointsPathEditMode.editing) &&
          path.vertices.isNotEmpty) {
        // We're in business; get the previous vertex and local mouse
        final lastVertex = path.vertices.last;
        final reference = Vec2D.fromValues(lastVertex.x, lastVertex.y);
        final origin = Vec2D.transformMat2D(
          Vec2D(),
          reference,
          path.pathTransform,
        );
        // Calculate what axis is the closest to the slope of the two points
        lockAxis = LockAxis(origin, _calculateLockAxis(worldMouse, origin));
      }
    }
    return super.mouseMove(activeArtboard, worldMouse);
  }

  /// Calculates the quadrant in which the world mouse is with reference to the
  /// previous vertex
  LockDirection _calculateLockAxis(Vec2D position, Vec2D origin) {
    // Calculate the slope of the line from reference to worldMouse
    final toPosition = Vec2D.subtract(Vec2D(), position, origin);
    final angle = atan2(toPosition[1], toPosition[0]);
    if (angle >= -pi / 8 && angle < pi / 8) {
      return LockDirection.x;
    } else if (angle >= pi / 8 && angle < pi / 8 * 3) {
      return LockDirection.neg45;
    } else if (angle >= pi / 8 * 3 && angle < pi / 8 * 5) {
      return LockDirection.y;
    } else if (angle >= pi / 8 * 5 && angle < pi / 8 * 7) {
      return LockDirection.pos45;
      // Angle will revert to negative
    } else if ((angle >= pi / 8 * 7 && angle < pi) ||
        angle >= -pi && angle < -pi / 8 * 7) {
      return LockDirection.x;
    } else if (angle >= -pi / 8 * 7 && angle < -pi / 8 * 5) {
      return LockDirection.neg45;
    } else if (angle >= -pi / 8 * 5 && angle < -pi / 8 * 3) {
      return LockDirection.y;
    } else if (angle >= -pi / 8 * 3 && angle < -pi / 8) {
      return LockDirection.pos45;
    }
    return LockDirection.x;
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
