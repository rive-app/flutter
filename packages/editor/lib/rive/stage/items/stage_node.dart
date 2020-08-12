import 'dart:typed_data';
import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable_component.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_hideable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// A Node component as it's drawn on the stage.
class StageNode extends HideableStageItem<Node>
    with BoundsDelegate, StageTransformableComponent<Node> {
  @override
  Iterable<StageDrawPass> get drawPasses => [
        StageDrawPass(
          draw,
          inWorldSpace: true,
          order: 3,
        )
      ];

  @override
  AABB get aabb {
    var aabb = AABB
        .fromValues(
            component.worldTransform[4] - _halfNodeSize,
            component.worldTransform[5] - _halfNodeSize,
            component.worldTransform[4] + _halfNodeSize,
            component.worldTransform[5] + _halfNodeSize)
        .translate(component.artboard.originWorld);
    return aabb;
  }

  @override
  bool intersectsRect(Float32List rectPoly) => true;

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    // TODO: make this efficient
    final state = selectionState.value;
    if (state == SelectionState.hovered || state == SelectionState.selected) {
      _nodeStroke.color = _nodeFill.color = StageItem.selectedPaint.color;
    } else {
      _nodeStroke.color = _nodeFill.color = _pathColor;
    }
    canvas.save();
    final origin = component.artboard.originWorld;
    canvas.translate(origin[0], origin[1]);
    canvas.transform(component.worldTransform.mat4);
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
    ..strokeWidth = 1.5
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

  @override
  void boundsChanged() {
    stage?.updateBounds(this);
  }
}
