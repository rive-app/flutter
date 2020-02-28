import 'dart:math';
import 'dart:ui' as ui;

import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';

export 'package:rive_core/src/generated/shapes/path_base.dart';

abstract class Path extends PathBase {
  final ui.Path _uiPath = ui.Path();
  ui.Path get uiPath => _uiPath;

  bool get isClosed;

  Shape _shape;

  Shape get shape => _shape;

  Mat2D get pathTransform;

  @override
  void visitAncestor(Component ancestor) {
    if (ancestor is Shape) {
      _changeShape(ancestor);
    }
  }

  void _changeShape(Shape value) {
    _shape?.removePath(this);
    value?.addPath(this);
    _shape = value;
  }

  @override
  void worldTransformed() {
    _shape?.pathChanged(this);
  }

  @override
  void update(int dirt) {
    super.update(dirt);

    if (dirt & ComponentDirt.path != 0) {
      _buildPath();
    }
  }

  List<PathVertex> get vertices;

  bool _buildPath() {
    _uiPath.reset();
    List<PathVertex> pts = vertices;
    if (pts == null || pts.isEmpty) {
      return false;
    }

    List<PathVertex> renderPoints = [];
    int pl = pts.length;

    const double arcConstant = 0.55;
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
                    ? previous.outPoint
                    : previous.translation;
                Vec2D nextPoint =
                    next is CubicVertex ? next.inPoint : next.translation;
                Vec2D pos = point.translation;

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
                renderPoints.add(CubicVertex()
                  ..translation = translation
                  ..inPoint = translation
                  ..outPoint = Vec2D.scaleAndAdd(
                      Vec2D(), pos, toPrev, iarcConstant * renderRadius));
                translation =
                    Vec2D.scaleAndAdd(Vec2D(), pos, toNext, renderRadius);
                previous = CubicVertex()
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

    PathVertex firstPoint = renderPoints[0];
    _uiPath.moveTo(firstPoint.translation[0], firstPoint.translation[1]);
    for (int i = 0,
            l = isClosed ? renderPoints.length : renderPoints.length - 1,
            pl = renderPoints.length;
        i < l;
        i++) {
      PathVertex point = renderPoints[i];
      PathVertex nextPoint = renderPoints[(i + 1) % pl];
      Vec2D cin = nextPoint is CubicVertex ? nextPoint.inPoint : null;
      Vec2D cout = point is CubicVertex ? point.outPoint : null;
      if (cin == null && cout == null) {
        _uiPath.lineTo(nextPoint.translation[0], nextPoint.translation[1]);
      } else {
        cout ??= point.translation;
        cin ??= nextPoint.translation;

        _uiPath.cubicTo(cout[0], cout[1], cin[0], cin[1],
            nextPoint.translation[0], nextPoint.translation[1]);
      }
    }

    if (isClosed) {
      _uiPath.close();
    }

    return true;
  }
}
