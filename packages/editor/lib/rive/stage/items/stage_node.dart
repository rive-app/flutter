import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// A Node component as it's drawn on the stage.
class StageNode extends StageItem<Node> {
  @override
  AABB get aabb => AABB
      .fromValues(component.x - _halfNodeSize, component.y - _halfNodeSize,
          component.x + _halfNodeSize, component.y + _halfNodeSize)
      .translate(component.artboard.originWorld);

  @override
  void paint(Canvas canvas) {
    final origin = component.artboard.originWorld;
    final x = component.x;
    final y = component.y;
    canvas.save();
    canvas.translate(origin[0] + x, origin[1] + y);
    canvas.drawPath(_nodeEdgePath, _nodeStroke);
    canvas.drawPath(_insidePath, _nodeFill);
    canvas.restore();
  }

  static const _nodeSize = 18;
  static const _halfNodeSize = _nodeSize / 2;
  static const _edgeSize = 6;
  static const _edgeThickness = 1.5;
  static const _halfEdgeThickness = _edgeThickness / 2;
  static const _pathColor = Color.fromRGBO(255, 255, 255, 0.5);
  static final Paint _nodeStroke = Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..blendMode = BlendMode.srcOver
    ..color = _pathColor;

  static final Paint _nodeFill = Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.srcOver
    ..color = _pathColor;

  // Lazily build the Canvas paths by using a closure that is evaulauted
  // in-place.
  // The following static fields are for when the node needs to be drawn
  // 'empty' (as opposed to 'target').
  static final Path _nodeEdgePath = () {
    final path = Path();
    path.moveTo(-_halfNodeSize + _halfEdgeThickness,
        -_halfNodeSize + _edgeSize - _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _edgeSize - _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);

    path.moveTo(_halfNodeSize - _edgeSize + _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);
    path.lineTo(_halfNodeSize - _halfEdgeThickness,
        -_halfNodeSize + _halfEdgeThickness);
    path.lineTo(_halfNodeSize - _halfEdgeThickness,
        -_halfNodeSize + _edgeSize - _halfEdgeThickness);

    path.moveTo(_halfNodeSize - _halfEdgeThickness,
        _halfNodeSize - _edgeSize + _halfEdgeThickness);
    path.lineTo(
        _halfNodeSize - _halfEdgeThickness, _halfNodeSize - _halfEdgeThickness);
    path.lineTo(_halfNodeSize - _edgeSize + _halfEdgeThickness,
        _halfNodeSize - _halfEdgeThickness);

    path.moveTo(-_halfNodeSize + _edgeSize - _halfEdgeThickness,
        _halfNodeSize - _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _halfEdgeThickness,
        _halfNodeSize - _halfEdgeThickness);
    path.lineTo(-_halfNodeSize + _halfEdgeThickness,
        _halfNodeSize - _edgeSize + _halfEdgeThickness);
    return path;
  }();

  static final Path _insidePath = () {
    final insidePath = Path();
    insidePath.moveTo(-_edgeThickness, -_edgeThickness);
    insidePath.lineTo(_edgeThickness, -_edgeThickness);
    insidePath.lineTo(_edgeThickness, _edgeThickness);
    insidePath.lineTo(-_edgeThickness, _edgeThickness);
    insidePath.close();

    return insidePath;
  }();
}
