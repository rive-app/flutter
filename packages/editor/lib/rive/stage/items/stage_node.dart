import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageNode extends StageItem<Node> with NodeDelegate {
  @override
  AABB get aabb {
    // TODO: properly evaluate.
    var x = _renderTransform[4];
    var y = _renderTransform[5];
    return AABB.fromValues(x - _halfNodeSize, y - _halfNodeSize,
        x + _halfNodeSize, y + _halfNodeSize);
  }

  Mat2D _renderTransform = Mat2D();

  @override
  bool initialize(Node component) {
    super.initialize(component);
    // Register this StageItem with its Node to receive update events.
    component.delegate = this;
    _renderTransform = component.renderTransform;

    return true;
  }

  @override
  void paint(Canvas canvas) {
    canvas.save();
    canvas.transform(_renderTransform.mat4);
    canvas.drawPath(_nodeEdgePath, _nodeStroke);
    canvas.drawPath(_insidePath, _nodeFill);
    canvas.restore();
  }

  @override
  void transformChanged() {
    _renderTransform = component.renderTransform;
  }

  @override
  void boundsChanged() {/** NOP */}

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
