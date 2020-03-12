import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageNode extends StageItem<Node> with NodeDelegate {
  static const _nodeSize = 18;

  @override
  AABB get aabb {
    var x = _renderTransform[4];
    var y = _renderTransform[5];
    return AABB.fromValues(
        x - _nodeSize, y - _nodeSize, x + _nodeSize, y + _nodeSize);
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
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10, height: 10),
        Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  @override
  void transformChanged() {
    _renderTransform = component.renderTransform;
  }

  @override
  void boundsChanged() {
    /** NOP */
  }
}
