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
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
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

    var path = PointsPath();
    if (shape == null) {
      shape = ShapeTool.makeShape(activeArtboard, path);
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

  /// Returns true if the vertex was given weight for bone binding.
  static bool _addVertex(PointsPath path, PathVertex vertex) {
    path.context.addObject(vertex);
    vertex.parent = path;
    if (path.skin != null) {
      vertex.initWeight();
      return true;
    }
    return false;
  }

  @override
  void click(Artboard activeArtboard, Vec2D worldMouse) {
    _clickCreatedVertex = null;
    if (insertTarget != null) {
      if (!_split()) {
        stage.file.addAlert(
          SimpleAlert('Failed to subdivide.'),
        );
      } else {
        // Make sure we clear the insert target after splitting as the old one
        // is invalid.
        clearInsertTarget();
      }
      return;
    }
    if (!isShowingGhostPoint) {
      return;
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
      _addVertex(path, vertex);
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
          var translation = lastVertex.renderTranslation;
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
              path.moveTo(translation[0], translation[1]);
              if (closeTarget is CubicVertex) {
                path.cubicTo(
                    lastVertex.renderOut[0],
                    lastVertex.renderOut[1],
                    closeTarget.renderIn[0],
                    closeTarget.renderIn[1],
                    targetOffset.dx,
                    targetOffset.dy);
              } else {
                path.cubicTo(
                    lastVertex.renderOut[0],
                    lastVertex.renderOut[1],
                    targetOffset.dx,
                    targetOffset.dy,
                    targetOffset.dx,
                    targetOffset.dy);
              }
              canvas.drawPath(path, StageItem.selectedPaint);
            } else if (closeTarget is CubicVertex) {
              var path = ui.Path();
              path.moveTo(translation[0], translation[1]);
              path.cubicTo(
                  translation[0],
                  translation[1],
                  closeTarget.renderIn[0],
                  closeTarget.renderIn[1],
                  targetOffset.dx,
                  targetOffset.dy);
              canvas.drawPath(path, StageItem.selectedPaint);
            } else {
              canvas.drawLine(Offset(translation[0], translation[1]),
                  targetOffset, StageItem.selectedPaint);
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
        PathVertexTranslateTransformer(
          lockRotationShortcut: ShortcutAction.symmetricDraw,
        ),
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
      var vertices = path.displayVertices;

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

        Vec2D controlOut = vertex is CubicVertex ? vertex.renderOut : null;
        Vec2D controlIn =
            nextVertex is CubicVertex ? nextVertex.renderIn : null;

        // There are no cubic control points, this is just a linear edge.
        if (controlIn == null && controlOut == null) {
          var v1 = vertex.renderTranslation;
          var v2 = nextVertex.renderTranslation;
          var t = Vec2D.onSegment(v1, v2, localMouse);
          if (t <= 0) {
            intersection = v1;
          } else if (t >= 1) {
            intersection = v2;
          } else {
            intersection = Vec2D.fromValues(
                v1[0] + (v2[0] - v1[0]) * t, v1[1] + (v2[1] - v1[1]) * t);
          }
        } else {
          // Either in, out, or both are cubic control points.
          controlOut ??= vertex.renderTranslation;
          controlIn ??= nextVertex.renderTranslation;
          cubicBezier = CubicBezier([
            Vector2(vertex.renderTranslation[0], vertex.renderTranslation[1]),
            Vector2(controlOut[0], controlOut[1]),
            Vector2(controlIn[0], controlIn[1]),
            Vector2(nextVertex.renderTranslation[0],
                nextVertex.renderTranslation[1])
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
        // and have different world transform.
        var intersectionWorld =
            Vec2D.transformMat2D(Vec2D(), intersection, path.pathTransform);

        double distance = Vec2D.distance(worldMouse, intersectionWorld);
        if (distance < closestPathDistance) {
          // If this is a cubic, don't allow splitting right on existing points.
          if (cubicBezier != null && (cubicSplitT <= 0 || cubicSplitT >= 1)) {
            continue;
          }

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
    var isBoundToBones = path.skin != null;
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
        _addVertex(path, vertex);
      });

      // Gotta wait for the stage vertex to have been created, unfortunately
      // that's after batch add. Our abstraction for setting world positions on
      // vertices is there, so need to do it like this for now. This'll
      // automatically invert the deformation to get to the correct local
      // position.
      if (isBoundToBones) {
        (vertex.stageItem as StageVertex).worldTranslation =
            path.artboard.renderTranslation(target.worldTranslation);
      }

      file.captureJournalEntry();
      autoKeySuppression.restore();
      return true;
    }

    // must split between the start/end.
    assert(target.cubicSplitT > 0 && target.cubicSplitT < 1);

    // Store a list of cubic vertices that'll need to be patched up.
    final patchBoundCubics =
        isBoundToBones ? <CubicVertex, _PatchCubicOperation>{} : null;

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
        CubicDetachedVertex vertexA, vertexB;
        var vertexIndex = vertices.indexOf(to.coreVertex);
        FractionalIndex before = vertexIndex == 0
            ? const FractionalIndex.min()
            : vertices[vertexIndex - 1].childOrder;
        FractionalIndex after = vertexIndex + 1 >= vertices.length
            ? const FractionalIndex.max()
            : vertices[vertexIndex + 1].childOrder;

        file.batchAdd(() {
          // Remove old corner point (and any associated weights)...It's
          // imperative that the weights get removed too otherwise they'll get
          // orphaned and pruned out by validation which means they won't be
          // regenerated when the nzext undo occurs.
          from.coreVertex.removeRecursive();

          // Add the corner cubics as real core points.
          vertexA = CubicDetachedVertex.fromValues(
            x: from.translation[0],
            y: from.translation[1],
            inX: from.inPoint[0],
            inY: from.inPoint[1],
            outX: from.outPoint[0],
            outY: from.outPoint[1],
          )..childOrder = FractionalIndex.between(before, after);

          vertexB = CubicDetachedVertex.fromValues(
            x: to.translation[0],
            y: to.translation[1],
            inX: to.inPoint[0],
            inY: to.inPoint[1],
            outX: to.outPoint[0],
            outY: to.outPoint[1],
          )..childOrder = FractionalIndex.between(vertexA.childOrder, after);

          _addVertex(path, vertexA);
          _addVertex(path, vertexB);

          if (isBoundToBones) {
            patchBoundCubics[vertexA] = _PatchCubicOperation.all;
            patchBoundCubics[vertexB] = _PatchCubicOperation.all;
          }

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

          newVertex.outPoint = leftSplit.points[1].toVec2D();
          if (isBoundToBones) {
            if (patchBoundCubics.containsKey(prev)) {
              // Do the same thing to the replacement.
              patchBoundCubics[newVertex] = patchBoundCubics[prev];
              patchBoundCubics.remove(prev);
            } else {
              patchBoundCubics[newVertex] = _PatchCubicOperation.outOnly;
            }
          }
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

          newVertex.inPoint = rightSplit.points[2].toVec2D();
          if (isBoundToBones) {
            if (patchBoundCubics.containsKey(next)) {
              // Do the same thing to the replacement.
              patchBoundCubics[newVertex] = patchBoundCubics[next];
              patchBoundCubics.remove(next);
            } else {
              patchBoundCubics[newVertex] = _PatchCubicOperation.inOnly;
            }
          }
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
      if (_addVertex(path, vertex)) {
        patchBoundCubics[vertex] = _PatchCubicOperation.all;
      }
    });
    patchBoundCubics?.forEach((vertex, mode) {
      var stageVertex = vertex.stageItem as StagePathVertex;
      // Local translations have been saved in world space during creation as
      // our paths are in world space when bound to bones. So we can use that
      // temporary stored value to patch up the actual desired (un-deformed)
      // local translation values.

      // First store the translations (changing these can cause re-compute of
      // others so we store the whole set first).
      var translation = path.artboard.renderTranslation(vertex.translation);
      var inTranslation = path.artboard.renderTranslation(vertex.inPoint);
      var outTranslation = path.artboard.renderTranslation(vertex.outPoint);

      switch (mode) {
        case _PatchCubicOperation.inOnly:
          stageVertex.controlIn.worldTranslation = inTranslation;
          break;
        case _PatchCubicOperation.outOnly:
          stageVertex.controlOut.worldTranslation = outTranslation;
          break;
        case _PatchCubicOperation.all:

          // Need to set the translation first, then the ins/outs as they use the
          // translation to compute angles.
          stageVertex.worldTranslation = translation;
          stageVertex.controlIn.worldTranslation = inTranslation;
          stageVertex.controlOut.worldTranslation = outTranslation;
      }
    });

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
      // Current editing path is in a hashset; go find it
      final path = editingPaths.firstWhere(
          (path) => path.editingMode == PointsPathEditMode.creating,
          orElse: () => null);

      if (path != null && path.vertices.isNotEmpty) {
        // We're in business; get the previous vertex and local mouse
        final lastVertex = path.vertices.last;
        final translation = lastVertex.renderTranslation;
        final reference = Vec2D.fromValues(translation[0], translation[1]);
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
  Vec2D _calculateLockAxis(Vec2D position, Vec2D origin) {
    var diff = Vec2D.subtract(Vec2D(), position, origin);

    var angle = atan2(diff[1], diff[0]);
    // 45 degree increments
    var lockInc = pi / 4;
    var lockAngle = (angle / lockInc).round() * lockInc;
    return Vec2D.fromValues(cos(lockAngle), sin(lockAngle));
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

enum _PatchCubicOperation { all, inOnly, outOnly }
