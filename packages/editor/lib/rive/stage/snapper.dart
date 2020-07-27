import 'dart:collection';
import 'dart:ui';

import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/segment2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/theme.dart';

final snapLineColor = RiveColors().snappingLine;

typedef SnappingFilter = bool Function(StageItem);

class _SnappingItem {
  final Mat2D toParent;
  final Vec2D worldTranslation;

  _SnappingItem(this.toParent, this.worldTranslation);
  factory _SnappingItem.fromNode(Node node) {
    var artboard = node.artboard;
    var world = artboard.transform(
        node.parent is Node ? (node.parent as Node).worldTransform : Mat2D());
    var inverse = Mat2D();
    if (!Mat2D.invert(inverse, world)) {
      return null;
    }
    return _SnappingItem(inverse,
        Mat2D.getTranslation(artboard.transform(node.worldTransform), Vec2D()));
  }
}

class _SnapAxis {
  final double value;
  final List<double> complements;

  _SnapAxis(this.value, this.complements);

  _SnapAxis mergeComplements(_SnapAxis other, double complementDelta) {
    return _SnapAxis(
        value,
        other.complements.map((v) => v + complementDelta).toList(growable: true)
          ..addAll(complements)
          ..sort());
  }
}

class _SnappingAxes {
  final _xPoints = HashMap<double, HashSet<double>>();
  final _yPoints = HashMap<double, HashSet<double>>();

  final axes = [<_SnapAxis>[], <_SnapAxis>[]];

  void add(StageItem item) {
    if (item is StageNode) {
      var center = AABB.center(Vec2D(), item.aabb);
      addPoint(center[0], center[1]);
    } else {
      var obb = item.obb;
      if (obb != null) {
        var poly = obb.poly;
        addPoint(poly[0], poly[1]);
        addPoint(poly[2], poly[3]);
        addPoint(poly[4], poly[5]);
        addPoint(poly[6], poly[7]);
        var center = obb.center;
        addPoint(center[0], center[1]);
      } else {
        addAABB(item.aabb);
      }
    }
  }

  void addAABB(AABB bounds) {
    //tl
    addPoint(bounds[0], bounds[1]);
    //tr
    addPoint(bounds[2], bounds[1]);
    //br
    addPoint(bounds[2], bounds[3]);
    //bl
    addPoint(bounds[0], bounds[3]);
    //bl
    var center = AABB.center(Vec2D(), bounds);
    addPoint(center[0], center[1]);
  }

  void addPoint(double px, double py) {
    var x = _xPoints[px];
    if (x == null) {
      x = HashSet<double>();
      _xPoints[px] = x;
    }
    x.add(py);

    var y = _yPoints[py];
    if (y == null) {
      y = HashSet<double>();
      _yPoints[py] = y;
    }
    y.add(px);
  }

  void complete() {
    var snapAxisX = axes[0];
    var snapAxisY = axes[1];
    _xPoints.forEach((x, ys) {
      snapAxisX.add(_SnapAxis(x, ys.toList(growable: false)..sort()));
    });
    _yPoints.forEach((y, xs) {
      snapAxisY.add(_SnapAxis(y, xs.toList(growable: false)..sort()));
    });
    snapAxisX.sort((a, b) => a.value.compareTo(b.value));
    snapAxisY.sort((a, b) => a.value.compareTo(b.value));
  }
}

/// A snapping context.
class Snapper {
  static const double snapDistance = 5;
  static const double snapIconRadius = 3;
  Stage _stage;

  // AABB dragBounds;

  final List<List<_SnapAxis>> _snapResult = [<_SnapAxis>[], <_SnapAxis>[]];
  final _targets = _SnappingAxes();
  final _source = _SnappingAxes();

  final Map<Node, _SnappingItem> _items = {};
  final Vec2D startMouse;

  Snapper.build(
      this.startMouse, Iterable<Node> nodes, SnappingFilter itemFilter)
      : assert(nodes.isNotEmpty),
        assert(nodes.first.stageItem.stage != null) {
    _stage = nodes.first.stageItem.stage;

    final exclusion = HashSet<Component>();
    for (final node in nodes) {
      node.forAll((component) {
        exclusion.add(component);
        return true;
      });
    }
    // x.add(100);
    _stage.visTree.all((id, item) {
      if (exclusion.contains(item.component)) {
        return true;
      }
      if (itemFilter(item)) {
        _targets.add(item);
      }

      return true;
    });
    _targets.complete();

    if (nodes.length > 1) {
      // Build up bounds
      AABB bounds = nodes.first.stageItem.aabb;
      for (final node in nodes.skip(1)) {
        AABB.combine(bounds, bounds, node.stageItem.aabb);
      }
      _source.addAABB(bounds);
    } else {
      _source.add(nodes.first.stageItem);
    }
    _source.complete();

    for (final node in nodes) {
      _items[node] = _SnappingItem.fromNode(node);
    }
  }

  void advance(Vec2D worldMouse, Vec2D lockAxis) {
    Vec2D diff;
    if (lockAxis == null) {
      diff = Vec2D.subtract(Vec2D(), worldMouse, startMouse);
    } else {
      var segment =
          Segment2D(startMouse, Vec2D.add(Vec2D(), startMouse, lockAxis));
      var result = segment.projectPoint(worldMouse, clamp: false);
      diff = Vec2D.subtract(Vec2D(), result.point, startMouse);
    }

    _snapResult[0].clear();
    _snapResult[1].clear();
    final List<List<_SnapAxis>> snapResultSource = [
      <_SnapAxis>[],
      <_SnapAxis>[]
    ];

    // Change in mouse diff to get to snap
    var diffDelta = Vec2D();

    for (int i = 0; i < 2; i++) {
      var threshold = snapDistance;
      // Store last screen difference without abs value to check if it matches
      // previous snap results (as we build up multiple snap results).
      double lastDiff = 0;
      for (final source in _source.axes[i]) {
        var checkX = source.value + diff[i];

        for (final cx in _targets.axes[i]) {
          var checkDiff = cx.value - checkX;

          var screenDiff = (checkDiff * _stage.viewZoom).abs();

          if (screenDiff <= threshold) {
            threshold = screenDiff;

            diffDelta[i] = checkDiff;
            var result = _snapResult[i];
            var resultSource = snapResultSource[i];

            // We store multiple results for the snap on each axis, but we clear
            // them out if the previous result isn't the same.
            if (lastDiff != checkDiff) {
              result.clear();
              resultSource.clear();
            }
            result.add(cx);
            resultSource.add(source);

            lastDiff = checkDiff;
          }
        }
      }
    }

    // After we've processed both axes, we can apply the difference. If we're
    // axis locked, we need to correct the diff on the opposite dimension, which
    // likely means breaking snap on that opposite dimension (if there was).
    for (int i = 0; i < 2; i++) {
      var componentA = i;
      var componentB = (i + 1) % 2;

      if (_snapResult[componentA].isNotEmpty) {
        diff[componentA] += diffDelta[componentA];
        // Don't process the lock axis if the denominator of the slope is 0.
        if (lockAxis != null && lockAxis[componentA] != 0) {
          // Solve for snap on opposite axis so the delta is is still on the
          // same locked slope.
          var axisAligned =
              diff[componentA] * (lockAxis[componentB] / lockAxis[componentA]);
          if (diff[componentB] != axisAligned) {
            // The change results in a different coordinate which requires
            // canceling the snap on that axis.
            diff[componentB] = axisAligned;
            _snapResult[componentB].clear();
            snapResultSource[componentB].clear();
          }
        }
      }
    }

    // After we've clamped the mouse move diff, fix up the complements. We need
    // to have snapped both diffs which is why we do this after the first loop.
    for (int i = 0; i < 2; i++) {
      var result = _snapResult[i];
      var resultSource = snapResultSource[i];
      assert(result.length == resultSource.length,
          'target snap axes and source snap axes must match');
      if (result.isNotEmpty) {
        // Merge the complements and move the original complements by the
        // snapped diff on the opposite axis.
        var oppositeComponent = (i + 1) % 2;
        for (int j = 0, l = result.length; j < l; j++) {
          result[j] = result[j]
              .mergeComplements(resultSource[j], diff[oppositeComponent]);
        }
      }
    }

    _items.forEach((node, details) {
      var world = Vec2D.add(Vec2D(), details.worldTranslation, diff);
      var local = Vec2D.transformMat2D(Vec2D(), world, details.toParent);
      node.x = local[0];
      node.y = local[1];
    });
  }

  final snapPointPath = Path()
    ..moveTo(-snapIconRadius, -snapIconRadius)
    ..lineTo(snapIconRadius, snapIconRadius)
    ..moveTo(-snapIconRadius, snapIconRadius)
    ..lineTo(snapIconRadius, -snapIconRadius);

  final snapPointPaint = Paint()
    ..color = snapLineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  void draw(Canvas canvas) {
    canvas.save();

    var transformComponents = [
      [0, 4],
      [3, 5]
    ];
    for (int i = 0; i < 2; i++) {
      var snap = _snapResult[i];
      if (snap.isNotEmpty) {
        for (final snapAxis in snap) {
          var viewTransform = _stage.viewTransform;

          var componentA = i;
          var componentB = (i + 1) % 2;

          var transformIndicesA = transformComponents[componentA];
          var transformIndicesB = transformComponents[componentB];

          var screenA = viewTransform[transformIndicesA[0]] * snapAxis.value +
              viewTransform[transformIndicesA[1]];

          var screenTranslate = Vec2D();
          screenTranslate[componentA] = screenA + 0.5;
          screenTranslate[componentB] = 0.5;

          canvas.save();
          canvas.translate(screenTranslate[0], screenTranslate[1]);

          var vtS = viewTransform[transformIndicesB[0]];
          var vtT = viewTransform[transformIndicesB[1]];

          double min, max;
          var complements = snapAxis.complements;
          screenTranslate[componentA] = 0;
          for (int i = 0, l = complements.length - 1; i <= l; i++) {
            var screenB = vtS * complements[i] + vtT;
            if (i == 0) {
              min = screenB;
            } else if (i == l) {
              max = screenB;
            }
            screenTranslate[componentB] = screenB;

            canvas.save();
            canvas.translate(screenTranslate[0], screenTranslate[1]);
            canvas.drawPath(snapPointPath, snapPointPaint);
            canvas.restore();
          }

          var start = Vec2D();
          start[componentB] = min;
          var end = Vec2D();
          end[componentB] = max;
          canvas.drawLine(Offset(start[0], start[1]), Offset(end[0], end[1]),
              snapPointPaint);
          canvas.restore();
        }
      }
    }
    canvas.restore();
  }
}
