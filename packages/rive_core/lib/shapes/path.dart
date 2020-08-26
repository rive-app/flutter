import 'dart:math';
import 'dart:ui' as ui;

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/circle_constant.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/display_cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';
export 'package:rive_core/src/generated/shapes/path_base.dart';

/// An abstract low level path that gets implemented by parametric and point
/// based paths.
abstract class Path extends PathBase {
  final Mat2D _inverseWorldTransform = Mat2D();

  final RenderPath _renderPath = RenderPath();
  ui.Path get uiPath {
    if (!_isValid) {
      _buildPath();
    }
    return _renderPath.uiPath;
  }

  bool _isValid = false;

  bool get isClosed;

  Shape _shape;

  Shape get shape => _shape;

  Mat2D get pathTransform;
  Mat2D get inversePathTransform;
  Mat2D get inverseWorldTransform => _inverseWorldTransform;

  // -> editor-only
  @override
  Component get timelineParent => _shape;
  // <- editor-only

  @override
  bool resolveArtboard() {
    _changeShape(null);
    return super.resolveArtboard();
  }

  // -> editor-only
  BoundsDelegate _delegate;

  void markBoundsDirty() {
    _delegate?.boundsChanged();
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }
  // <- editor-only

  @override
  void visitAncestor(Component ancestor) {
    if (_shape == null && ancestor is Shape) {
      _changeShape(ancestor);
    }
  }

  void _changeShape(Shape value) {
    if (_shape == value) {
      return;
    }
    _shape?.removePath(this);
    value?.addPath(this);
    _shape = value;
  }

  @override
  void onRemoved() {
    // We're no longer a child of the shape we may have been under, make sure to
    // let it know we're gone.
    _changeShape(null);
    super.onRemoved();
  }

  @override
  void updateWorldTransform() {
    super.updateWorldTransform();
    _shape?.pathChanged(this);

    // Paths store their inverse world so that it's available for skinning and
    // other operations that occur at runtime.
    if (!Mat2D.invert(_inverseWorldTransform, worldTransform)) {
      // If for some reason the inversion fails (like we have a 0 scale) just
      // store the identity.
      Mat2D.identity(_inverseWorldTransform);
    }
  }

  @override
  void update(int dirt) {
    super.update(dirt);

    if (dirt & ComponentDirt.path != 0) {
      _buildPath();
    }
  }

  /// Subclasses should call this whenever a parameter that affects the topology
  /// of the path changes in order to allow the system to rebuild the parametric
  /// path.
  /// should @internal when supported
  void markPathDirty() {
    addDirt(ComponentDirt.path);
    _isValid = false;
    _shape?.pathChanged(this);

    // -> editor-only
    _cachedDisplayVertices = null;
    // <- editor-only
  }

  List<PathVertex> get vertices;

  bool _buildPath() {
    _isValid = true;
    _renderPath.reset();
    List<PathVertex> vertices = this.vertices;
    var length = vertices.length;
    if (vertices == null || length < 2) {
      return false;
    }

    var firstPoint = vertices.first;
    double outX, outY;
    bool prevIsCubic;

    double startX, startY;
    double startInX, startInY;
    bool startIsCubic;

    if (firstPoint is CubicVertex) {
      startIsCubic = prevIsCubic = true;
      var inPoint = firstPoint.renderIn;
      startInX = inPoint[0];
      startInY = inPoint[1];
      var outPoint = firstPoint.renderOut;
      outX = outPoint[0];
      outY = outPoint[1];
      var translation = firstPoint.renderTranslation;
      startX = translation[0];
      startY = translation[1];
      _renderPath.moveTo(startX, startY);
    } else {
      startIsCubic = prevIsCubic = false;
      var point = firstPoint as StraightVertex;

      var radius = point.radius;
      if (radius > 0) {
        var prev = vertices[length - 1];

        var pos = point.renderTranslation;

        var toPrev = Vec2D.subtract(Vec2D(),
            prev is CubicVertex ? prev.renderOut : prev.renderTranslation, pos);
        var toPrevLength = Vec2D.length(toPrev);
        toPrev[0] /= toPrevLength;
        toPrev[1] /= toPrevLength;

        var next = vertices[1];

        var toNext = Vec2D.subtract(Vec2D(),
            next is CubicVertex ? next.renderIn : next.renderTranslation, pos);
        var toNextLength = Vec2D.length(toNext);
        toNext[0] /= toNextLength;
        toNext[1] /= toNextLength;

        var renderRadius = min(toPrevLength, min(toNextLength, radius));

        var translation = Vec2D.scaleAndAdd(Vec2D(), pos, toPrev, renderRadius);
        _renderPath.moveTo(startInX = startX = translation[0],
            startInY = startY = translation[1]);

        var outPoint = Vec2D.scaleAndAdd(
            Vec2D(), pos, toPrev, icircleConstant * renderRadius);

        var inPoint = Vec2D.scaleAndAdd(
            Vec2D(), pos, toNext, icircleConstant * renderRadius);

        var posNext = Vec2D.scaleAndAdd(Vec2D(), pos, toNext, renderRadius);
        _renderPath.cubicTo(outPoint[0], outPoint[1], inPoint[0], inPoint[1],
            outX = posNext[0], outY = posNext[1]);
        prevIsCubic = false;
      } else {
        var translation = point.renderTranslation;
        outX = translation[0];
        outY = translation[1];
        _renderPath.moveTo(startInX = startX = outX, startInY = startY = outY);
      }
    }

    for (int i = 1; i < length; i++) {
      var vertex = vertices[i];

      if (vertex is CubicVertex) {
        var inPoint = vertex.renderIn;
        var translation = vertex.renderTranslation;
        _renderPath.cubicTo(
            outX, outY, inPoint[0], inPoint[1], translation[0], translation[1]);

        prevIsCubic = true;
        var outPoint = vertex.renderOut;
        outX = outPoint[0];
        outY = outPoint[1];
      } else {
        var point = vertex as StraightVertex;

        var radius = point.radius;
        if (radius > 0) {
          var pos = point.renderTranslation;

          var toPrev =
              Vec2D.subtract(Vec2D(), Vec2D.fromValues(outX, outY), pos);
          var toPrevLength = Vec2D.length(toPrev);
          toPrev[0] /= toPrevLength;
          toPrev[1] /= toPrevLength;

          var next = vertices[(i + 1) % length];

          var toNext = Vec2D.subtract(
              Vec2D(),
              next is CubicVertex ? next.renderIn : next.renderTranslation,
              pos);
          var toNextLength = Vec2D.length(toNext);
          toNext[0] /= toNextLength;
          toNext[1] /= toNextLength;

          var renderRadius = min(toPrevLength, min(toNextLength, radius));

          var translation =
              Vec2D.scaleAndAdd(Vec2D(), pos, toPrev, renderRadius);
          if (prevIsCubic) {
            _renderPath.cubicTo(outX, outY, translation[0], translation[1],
                translation[0], translation[1]);
          } else {
            _renderPath.lineTo(translation[0], translation[1]);
          }

          var outPoint = Vec2D.scaleAndAdd(
              Vec2D(), pos, toPrev, icircleConstant * renderRadius);

          var inPoint = Vec2D.scaleAndAdd(
              Vec2D(), pos, toNext, icircleConstant * renderRadius);

          var posNext = Vec2D.scaleAndAdd(Vec2D(), pos, toNext, renderRadius);
          _renderPath.cubicTo(outPoint[0], outPoint[1], inPoint[0], inPoint[1],
              outX = posNext[0], outY = posNext[1]);
          prevIsCubic = false;
        } else if (prevIsCubic) {
          var translation = point.renderTranslation;
          var x = translation[0];
          var y = translation[1];
          _renderPath.cubicTo(outX, outY, x, y, x, y);

          prevIsCubic = false;
          outX = x;
          outY = y;
        } else {
          var translation = point.renderTranslation;
          outX = translation[0];
          outY = translation[1];
          _renderPath.lineTo(outX, outY);
        }
      }
    }
    if (isClosed) {
      if (prevIsCubic || startIsCubic) {
        _renderPath.cubicTo(outX, outY, startInX, startInY, startX, startY);
      }
      _renderPath.close();
    }
    return true;
  }

  // -> editor-only
  @override
  bool validate() => _shape != null;

  @override
  bool isValidParent(Component parent) {
    // A parent for the path is valid if somewhere in its direct ancestors
    // there's a shape.
    for (var nextParent = parent;
        nextParent != null;
        nextParent = nextParent.parent) {
      if (nextParent is Shape) {
        return true;
      }
    }
    return false;
  }

  @override
  AABB get localBounds => _renderPath.preciseComputeBounds();
  AABB preciseComputeBounds(Mat2D transform) =>
      _renderPath.preciseComputeBounds(transform);
  bool get hasBounds => _renderPath.hasBounds;

  // We keep this logic around for the pen tool to use to figure out where to
  // split the display path.
  List<PathVertex> _cachedDisplayVertices;

  List<PathVertex> get displayVertices {
    // TODO: add skin deformation (bones)
    if (_cachedDisplayVertices != null) {
      return _cachedDisplayVertices;
    }
    return _cachedDisplayVertices = makeDisplayVertices(vertices, isClosed);
  }

  static List<PathVertex> makeDisplayVertices(
      List<PathVertex> pts, bool isClosed) {
    if (pts == null || pts.isEmpty) {
      return [];
    }
    List<PathVertex> renderPoints = [];
    int pl = pts.length;

    const arcConstant = circleConstant;
    const double iarcConstant = 1.0 - arcConstant;
    PathVertex previous = isClosed ? pts[pl - 1] : null;
    for (int i = 0; i < pl; i++) {
      PathVertex point = pts[i];
      switch (point.coreType) {
        case StraightVertexBase.typeKey:
          {
            StraightVertex straightPoint = point as StraightVertex;
            double radius = straightPoint.radius;
            if (radius != null && radius > 0) {
              if (!isClosed && (i == 0 || i == pl - 1)) {
                renderPoints.add(point);
                previous = point;
              } else {
                PathVertex next = pts[(i + 1) % pl];
                Vec2D prevPoint = previous is CubicVertex
                    ? previous.renderOut
                    : previous.renderTranslation;
                Vec2D nextPoint = next is CubicVertex
                    ? next.renderIn
                    : next.renderTranslation;
                Vec2D pos = point.renderTranslation;

                Vec2D toPrev = Vec2D.subtract(Vec2D(), prevPoint, pos);
                double toPrevLength = Vec2D.length(toPrev);
                toPrev[0] /= toPrevLength;
                toPrev[1] /= toPrevLength;

                Vec2D toNext = Vec2D.subtract(Vec2D(), nextPoint, pos);
                double toNextLength = Vec2D.length(toNext);
                toNext[0] /= toNextLength;
                toNext[1] /= toNextLength;

                double renderRadius =
                    min(toPrevLength, min(toNextLength, radius));

                Vec2D translation =
                    Vec2D.scaleAndAdd(Vec2D(), pos, toPrev, renderRadius);
                renderPoints.add(DisplayCubicVertex()
                  // -> editor-only
                  ..original = point
                  ..isCornerRadius = true
                  // <- editor-only
                  ..translation = translation
                  ..inPoint = translation
                  ..outPoint = Vec2D.scaleAndAdd(
                      Vec2D(), pos, toPrev, iarcConstant * renderRadius));
                translation =
                    Vec2D.scaleAndAdd(Vec2D(), pos, toNext, renderRadius);
                previous = DisplayCubicVertex()
                  // -> editor-only
                  ..original = point
                  ..isCornerRadius = true
                  // <- editor-only
                  ..translation = translation
                  ..inPoint = Vec2D.scaleAndAdd(
                      Vec2D(), pos, toNext, iarcConstant * renderRadius)
                  ..outPoint = translation;
                renderPoints.add(previous);
              }
            } else {
              renderPoints.add(point);
              previous = point;
            }
            break;
          }
        default:
          renderPoints.add(point);
          previous = point;
          break;
      }
    }
    return renderPoints;
  }

  // <- editor-only
}

// -> editor-only
enum _PathCommand { moveTo, lineTo, cubicTo, close }
// <- editor-only

class RenderPath {
  final ui.Path _uiPath = ui.Path();
  ui.Path get uiPath => _uiPath;
  // -> editor-only
  final List<_PathCommand> _commands = [];
  final List<double> _positions = [];
  // <- editor-only

  void reset() {
    // -> editor-only
    _commands.clear();
    _positions.clear();
    // <- editor-only
    _uiPath.reset();
  }

  void lineTo(double x, double y) {
    // -> editor-only
    _commands.add(_PathCommand.lineTo);
    _positions.add(x);
    _positions.add(y);
    // <- editor-only}
    _uiPath.lineTo(x, y);
  }

  void moveTo(double x, double y) {
    // -> editor-only
    _commands.add(_PathCommand.moveTo);
    _positions.add(x);
    _positions.add(y);
    // <- editor-only
    _uiPath.moveTo(x, y);
  }

  void cubicTo(double ox, double oy, double ix, double iy, double x, double y) {
    // -> editor-only
    _commands.add(_PathCommand.cubicTo);
    _positions.add(ox);
    _positions.add(oy);
    _positions.add(ix);
    _positions.add(iy);
    _positions.add(x);
    _positions.add(y);
    // <- editor-only
    _uiPath.cubicTo(ox, oy, ix, iy, x, y);
  }

  void close() {
    // -> editor-only
    _commands.add(_PathCommand.close);
    // <- editor-only
    _uiPath.close();
  }

  // -> editor-only

  bool get isClosed =>
      _commands.isNotEmpty && _commands.last == _PathCommand.close;

  bool get hasBounds {
    return _commands.length > 1;
  }

  AABB preciseComputeBounds([Mat2D transform]) {
    if (_commands.isEmpty) {
      return AABB.empty();
    }
    // Compute the extremas and use them to expand the bounds as detailed here:
    // https://pomax.github.io/bezierinfo/#extremities

    AABB bounds = AABB.empty();
    var idx = 0;
    var penPosition = Vec2D();
    for (final command in _commands) {
      switch (command) {
        case _PathCommand.lineTo:
          // Pen position already transformed...
          bounds.includePoint(penPosition, null);
          penPosition = bounds.includePoint(
              Vec2D.fromValues(_positions[idx++], _positions[idx++]),
              transform);

          break;
        // We only do moveTo at the start, effectively always the start of the
        // first line segment (so always include it).
        case _PathCommand.moveTo:
          penPosition[0] = _positions[idx++];
          penPosition[1] = _positions[idx++];
          if (transform != null) {
            Vec2D.transformMat2D(penPosition, penPosition, transform);
          }

          break;
        case _PathCommand.cubicTo:
          var outPoint = Vec2D.fromValues(_positions[idx++], _positions[idx++]);
          var inPoint = Vec2D.fromValues(_positions[idx++], _positions[idx++]);
          var point = Vec2D.fromValues(_positions[idx++], _positions[idx++]);
          if (transform != null) {
            Vec2D.transformMat2D(outPoint, outPoint, transform);
            Vec2D.transformMat2D(inPoint, inPoint, transform);
            Vec2D.transformMat2D(point, point, transform);
          }
          _expandBoundsForAxis(
              bounds, 0, penPosition[0], outPoint[0], inPoint[0], point[0]);
          _expandBoundsForAxis(
              bounds, 1, penPosition[1], outPoint[1], inPoint[1], point[1]);
          penPosition = point;
          break;
        case _PathCommand.close:
          break;
      }
    }
    return bounds;
  }
  // <- editor-only
}

/// Expand our bounds to a point (in normalized T space) on the Cubic.
void _expandBoundsToCubicPoint(AABB bounds, int component, double t, double a,
    double b, double c, double d) {
  if (t >= 0 && t <= 1) {
    var ti = 1 - t;
    double extremaY = ((ti * ti * ti) * a) +
        ((3 * ti * ti * t) * b) +
        ((3 * ti * t * t) * c) +
        (t * t * t * d);
    if (extremaY < bounds[component]) {
      bounds[component] = extremaY;
    }
    if (extremaY > bounds[component + 2]) {
      bounds[component + 2] = extremaY;
    }
  }
}

void _expandBoundsForAxis(AABB bounds, int component, double start, double cp1,
    double cp2, double end) {
  if (!(((start < cp1) && (cp1 < cp2) && (cp2 < end)) ||
      ((start > cp1) && (cp1 > cp2) && (cp2 > end)))) {
    // Find the first derivative
    var a = 3 * (cp1 - start);
    var b = 3 * (cp2 - cp1);
    var c = 3 * (end - cp2);
    var d = a - 2 * b + c;

    // Solve roots for first derivative.
    if (d != 0) {
      var m1 = -sqrt(b * b - a * c);
      var m2 = -a + b;

      // First root.
      _expandBoundsToCubicPoint(
          bounds, component, -(m1 + m2) / d, start, cp1, cp2, end);
      _expandBoundsToCubicPoint(
          bounds, component, -(-m1 + m2) / d, start, cp1, cp2, end);
    } else if (b != c && d == 0) {
      _expandBoundsToCubicPoint(
          bounds, component, (2 * b - c) / (2 * (b - c)), start, cp1, cp2, end);
    }

    // Derive the first derivative to get the 2nd and use the root of
    // that (linear).
    var d2a = 2 * (b - a);
    var d2b = 2 * (c - b);
    if (d2a != b) {
      _expandBoundsToCubicPoint(
          bounds, component, d2a / (d2a - d2b), start, cp1, cp2, end);
    }
  }
}
