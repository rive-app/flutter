import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide ClipPath;
import 'package:flutter_svg/src/utilities/numbers.dart';
import 'package:flutter_svg/src/utilities/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:xml/xml_events.dart' hide parseEvents;

typedef _PathFunc = Path Function(List<XmlEventAttribute> attributes);

const Map<String, _PathFunc> svgPathFuncs = <String, _PathFunc>{
  'circle': _Paths.circle,
  'path': _Paths.path,
  'rect': _Paths.rect,
  'polygon': _Paths.polygon,
  'polyline': _Paths.polyline,
  'ellipse': _Paths.ellipse,
  'line': _Paths.line,
};

enum pathFuncs {
  addOval,
  addRect,
  addRRect,
  addPath,
  addArc,
  addPolygon,
  lineTo,
  arcTo,
  arcToPoint,
  relativeMoveTo,
  relativeLineTo,
  relativeArcToPoint,
  quadraticBezierTo,
  relativeQuadraticBezierTo,
  close,
  moveTo,
  conicTo,
  relativeConicTo,
  cubicTo,
  relativeCubicTo,
  transform,
}

class RivePath extends Path {
  RivePath()
      : instructions = <dynamic>[],
        super();

  List<dynamic> instructions;
  @override
  void addOval(Rect oval) {
    instructions.add([pathFuncs.addOval, oval]);
    super.addOval(oval);
  }

  @override
  void addRect(Rect rect) {
    instructions.add([pathFuncs.addRect, rect]);
    super.addRect(rect);
  }

  @override
  void addRRect(RRect rrect) {
    instructions.add([pathFuncs.addRRect, rrect]);
    super.addRRect(rrect);
  }

  @override
  void addPath(Path path, Offset offset, {Float64List matrix4}) {
    instructions.add([pathFuncs.addPath, path, offset, matrix4]);
    super.addPath(path, offset, matrix4: matrix4);
  }

  @override
  void addArc(Rect oval, double startAngle, double sweepAngle) {
    instructions.add([pathFuncs.addArc, startAngle, sweepAngle]);
    super.addArc(oval, startAngle, sweepAngle);
  }

  @override
  void addPolygon(List<Offset> points, bool close) {
    instructions.add([pathFuncs.addPolygon, points, close]);
    super.addPolygon(points, close);
  }

  @override
  void lineTo(double x, double y) {
    instructions.add([pathFuncs.lineTo, x, y]);
    super.lineTo(x, y);
  }

  @override
  void arcTo(
      Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    instructions
        .add([pathFuncs.arcTo, rect, startAngle, sweepAngle, forceMoveTo]);
    super.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
  }

  @override
  void arcToPoint(Offset arcEnd,
      {bool clockwise: true,
      bool largeArc: false,
      Radius radius: Radius.zero,
      double rotation: 0}) {
    instructions.add(
        [pathFuncs.arcToPoint, arcEnd, clockwise, largeArc, radius, rotation]);
    super.arcToPoint(arcEnd,
        clockwise: clockwise,
        largeArc: largeArc,
        radius: radius,
        rotation: rotation);
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    instructions.add([pathFuncs.relativeMoveTo, dx, dy]);
    super.relativeMoveTo(dx, dy);
  }

  @override
  void relativeLineTo(double dx, double dy) {
    instructions.add([pathFuncs.relativeLineTo, dx, dy]);
    super.relativeLineTo(dx, dy);
  }

  @override
  void relativeArcToPoint(Offset arcEnd,
      {bool clockwise: true,
      bool largeArc: false,
      Radius radius: Radius.zero,
      double rotation: 0}) {
    instructions.add([
      pathFuncs.relativeArcToPoint,
      arcEnd,
      clockwise,
      largeArc,
      radius,
      rotation
    ]);
    super.relativeArcToPoint(arcEnd,
        clockwise: clockwise,
        largeArc: largeArc,
        radius: radius,
        rotation: rotation);
  }

  @override
  RivePath transform(Float64List matrix4) {
    //TODO: figure out what we're doing with transform.
    // we currently dont evalutate this really....

    // instructions.add([pathFuncs.transform, matrix4]);
    // final RivePath path = RivePath();
    // path.instructions.addAll(instructions);
    // _transform(path, matrix4);
    return this;
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    instructions.add([pathFuncs.quadraticBezierTo, x1, y1, x2, y2]);
    super.quadraticBezierTo(x1, y1, x2, y2);
  }

  @override
  void relativeQuadraticBezierTo(
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    instructions.add([pathFuncs.relativeQuadraticBezierTo, x1, y1, x2, y2]);
    super.relativeQuadraticBezierTo(x1, y1, x2, y2);
  }

  @override
  void close() {
    instructions.add([pathFuncs.close]);
    super.close();
  }

  @override
  void moveTo(double x, double y) {
    instructions.add([pathFuncs.moveTo, x, y]);
    super.moveTo(x, y);
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    instructions.add([pathFuncs.conicTo, x1, y1, x2, y2, w]);
    super.conicTo(x1, y1, x2, y2, w);
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    instructions.add([pathFuncs.relativeConicTo, x1, y1, x2, y2, w]);
    super.relativeConicTo(x1, y1, x2, y2, w);
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    instructions.add([pathFuncs.cubicTo, x1, y1, x2, y2, x3, y3]);
    super.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    instructions.add([pathFuncs.relativeCubicTo, x1, y1, x2, y2, x3, y3]);
    super.relativeCubicTo(x1, y1, x2, y2, x3, y3);
  }
}

class _Paths {
  static RivePath circle(List<XmlEventAttribute> attributes) {
    final double cx = parseDouble(getAttribute(attributes, 'cx', def: '0'));
    final double cy = parseDouble(getAttribute(attributes, 'cy', def: '0'));
    final double r = parseDouble(getAttribute(attributes, 'r', def: '0'));
    final Rect oval = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    return RivePath()..addOval(oval);
  }

  static RivePath path(List<XmlEventAttribute> attributes) {
    final String d = getAttribute(attributes, 'd');
    return parseSvgPathData(d);
  }

  static RivePath rect(List<XmlEventAttribute> attributes) {
    final double x = parseDouble(getAttribute(attributes, 'x', def: '0'));
    final double y = parseDouble(getAttribute(attributes, 'y', def: '0'));
    final double w = parseDouble(getAttribute(attributes, 'width', def: '0'));
    final double h = parseDouble(getAttribute(attributes, 'height', def: '0'));
    final Rect rect = Rect.fromLTWH(x, y, w, h);
    String rxRaw = getAttribute(attributes, 'rx', def: null);
    String ryRaw = getAttribute(attributes, 'ry', def: null);
    rxRaw ??= ryRaw;
    ryRaw ??= rxRaw;

    if (rxRaw != null && rxRaw != '') {
      final double rx = parseDouble(rxRaw);
      final double ry = parseDouble(ryRaw);

      return RivePath()..addRRect(RRect.fromRectXY(rect, rx, ry));
    }

    return RivePath()..addRect(rect);
  }

  static RivePath polygon(List<XmlEventAttribute> attributes) {
    return parsePathFromPoints(attributes, true);
  }

  static RivePath polyline(List<XmlEventAttribute> attributes) {
    return parsePathFromPoints(attributes, false);
  }

  static RivePath parsePathFromPoints(
      List<XmlEventAttribute> attributes, bool close) {
    final String points = getAttribute(attributes, 'points');
    if (points == '') {
      return null;
    }
    final String path = 'M$points${close ? 'z' : ''}';

    return parseSvgPathData(path);
  }

  static RivePath ellipse(List<XmlEventAttribute> attributes) {
    final double cx = parseDouble(getAttribute(attributes, 'cx', def: '0'));
    final double cy = parseDouble(getAttribute(attributes, 'cy', def: '0'));
    final double rx = parseDouble(getAttribute(attributes, 'rx', def: '0'));
    final double ry = parseDouble(getAttribute(attributes, 'ry', def: '0'));

    final Rect r = Rect.fromLTWH(cx - rx, cy - ry, rx * 2, ry * 2);
    return RivePath()..addOval(r);
  }

  static RivePath line(List<XmlEventAttribute> attributes) {
    final double x1 = parseDouble(getAttribute(attributes, 'x1', def: '0'));
    final double x2 = parseDouble(getAttribute(attributes, 'x2', def: '0'));
    final double y1 = parseDouble(getAttribute(attributes, 'y1', def: '0'));
    final double y2 = parseDouble(getAttribute(attributes, 'y2', def: '0'));

    return RivePath()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);
  }
}

List<Component> getPaths(RiveFile file, RivePath rivePath, Offset shapeOffset) {
  // moveTo gets a maybevertex, multiple moves get ignored.
  dynamic moveInstruction;
  dynamic firstVertexInstruction;
  var components = <Component>[];
  var vertices = <PathVertex>[];
  for (var i = 0; i < rivePath.instructions.length; i++) {
    dynamic instruction = rivePath.instructions[i];
    switch (instruction[0] as pathFuncs) {
      case pathFuncs.moveTo:
        if (vertices.isNotEmpty) {
          var path = PointsPath()
            ..isClosed = false
            ..x = 0
            ..y = 0;
          file.addObject(path);
          vertices.forEach((element) {
            file.addObject(element);
            path.appendChild(element);
          });

          components.add(path);
          vertices = <PathVertex>[];
        }
        moveInstruction = instruction;
        break;
      case pathFuncs.addOval:
        if (vertices.isNotEmpty || rivePath.instructions.length != 1) {
          throw Exception('wtf');
        }
        var rect = instruction[1] as Rect;
        var ellipse = Ellipse()
          ..x = rect.left + rect.width / 2 - shapeOffset.dx
          ..y = rect.top + rect.height / 2 - shapeOffset.dy
          ..width = rect.width
          ..height = rect.height;
        file.addObject(ellipse);
        components.add(ellipse);
        break;
      case pathFuncs.lineTo:
        firstVertexInstruction ??= instruction;
        if (moveInstruction != null) {
          var moveVertex = StraightVertex()
            ..x = (moveInstruction[1] as double) - shapeOffset.dx
            ..y = (moveInstruction[2] as double) - shapeOffset.dy;
          vertices.add(moveVertex);
        }
        var vertex = StraightVertex()
          ..x = (instruction[1] as double) - shapeOffset.dx
          ..y = (instruction[2] as double) - shapeOffset.dy;
        vertices.add(vertex);
        moveInstruction = null;
        break;
      case pathFuncs.cubicTo:
        if (moveInstruction != null) {
          var moveVertex = CubicDetachedVertex()
            ..x = (moveInstruction[1] as double) - shapeOffset.dx
            ..y = (moveInstruction[2] as double) - shapeOffset.dy
            ..outPoint = Vec2D.fromValues(
                (instruction[1] as double) - shapeOffset.dx,
                (instruction[2] as double) - shapeOffset.dy);
          vertices.add(moveVertex);
        }

        firstVertexInstruction ??= instruction;

        if (vertices.isNotEmpty) {
          Vec2D inPoint;
          if (vertices.last.runtimeType == CubicDetachedVertex) {
            inPoint = (vertices.last as CubicDetachedVertex).inPoint;
          }
          vertices.last = CubicDetachedVertex()
            ..x = vertices.last.x
            ..y = vertices.last.y
            ..outPoint = Vec2D.fromValues(
              (instruction[1] as double) - shapeOffset.dx,
              (instruction[2] as double) - shapeOffset.dy,
            );
          if (inPoint != null) {
            (vertices.last as CubicDetachedVertex).inPoint = inPoint;
          }
        }
        var vertex = CubicDetachedVertex()
          ..x = (instruction[5] as double) - shapeOffset.dx
          ..y = (instruction[6] as double) - shapeOffset.dy
          ..inPoint = Vec2D.fromValues(
            (instruction[3] as double) - shapeOffset.dx,
            (instruction[4] as double) - shapeOffset.dy,
          );
        vertices.add(vertex);
        moveInstruction = null;
        break;
      case pathFuncs.close:
        if (vertices.isNotEmpty) {
          var path = PointsPath()
            ..isClosed = true
            ..x = 0
            ..y = 0;
          file.addObject(path);
          vertices.forEach((element) {
            file.addObject(element);
            path.appendChild(element);
          });

          components.add(path);
        }

        firstVertexInstruction = null;
        moveInstruction = null;
        vertices = [];

        break;
      case pathFuncs.addRect:
        var rect = instruction[1] as Rect;
        var rectangle = Rectangle()
          ..x = rect.left + rect.width / 2 - shapeOffset.dx
          ..y = rect.top + rect.height / 2 - shapeOffset.dy
          ..width = rect.width
          ..height = rect.height;
        file.addObject(rectangle);
        components.add(rectangle);
        break;
      case pathFuncs.addRRect:
        // todo: fix corner radius

        var rect = instruction[1] as RRect;

        var radiusSet = <double>{
          rect.blRadiusX,
          rect.blRadiusY,
          rect.brRadiusX,
          rect.brRadiusY,
          rect.tlRadiusX,
          rect.tlRadiusY,
          rect.trRadiusX,
          rect.trRadiusY
        };

        if (radiusSet.length > 1) {
          print('funky radius setup');
        }

        var rectangle = Rectangle()
          ..x = rect.left + rect.width / 2 - shapeOffset.dx
          ..y = rect.top + rect.height / 2 - shapeOffset.dy
          ..width = rect.width
          ..height = rect.height
          ..cornerRadius = radiusSet.first;
        file.addObject(rectangle);
        components.add(rectangle);
        break;
      case pathFuncs.transform:
        // DO NOT apply transforms to these paths
        // these transforms get applied to the shapes
        break;
      default:
        firstVertexInstruction = null;
        moveInstruction = null;
        print('dunno how to deal with $instruction');
    }
  }

  if (vertices.isNotEmpty) {
    var path = PointsPath()
      ..isClosed = false
      ..x = 0
      ..y = 0;
    file.addObject(path);
    vertices.forEach((element) {
      file.addObject(element);
      path.appendChild(element);
    });

    components.add(path);
  }

  return components;
}

RivePath parseSvgPathData(String svg) {
  if (svg == null) {
    return null;
  }
  if (svg == '') {
    return RivePath();
  }

  final SvgPathStringSource parser = SvgPathStringSource(svg);
  final RivePathProxy path = RivePathProxy();
  final SvgPathNormalizer normalizer = SvgPathNormalizer();
  for (final seg in parser.parseSegments()) {
    normalizer.emitSegment(seg, path);
  }
  return path.path;
}

class RivePathProxy extends FlutterPathProxy {
  RivePathProxy({RivePath p}) : path = p ?? RivePath();

  // i know, i know its disgusting
  @override
  final RivePath path;

  @override
  void close() {
    path.close();
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
  }
}
