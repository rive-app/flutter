import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_control_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// Implementation of StageVertex for CubicVertex and StraightVertex.
class StagePathVertex extends StageVertex<PathVertex> {
  StageControlVertex _in, _out;

  @override
  double get radiusScale =>
      component.path.vertices.first == component ? 1.5 : 1;

  bool get hasControlPoints => component.coreType == CubicVertexBase.typeKey;

  @override
  void addedToStage(Stage stage) {
    if (hasControlPoints) {
      var cubic = component as CubicVertex;
      assert(_in == null, 'shouldn\'t have in/out when first added to stage');
      assert(
          cubic != null,
          'StageVertex with control points '
          'must be backed by a CubicVertex component');
      _in = StageControlIn();
      _in.initialize(component as CubicVertex);

      _out = StageControlOut();
      _out.initialize(component as CubicVertex);
      stage.addItem(_in);
      stage.addItem(_out);
    }
    super.addedToStage(stage);
  }

  @override
  void removedFromStage(Stage stage) {
    if (hasControlPoints) {
      assert(_in != null);
      stage.removeItem(_in);
      stage.removeItem(_out);
      _in = _out = null;
    }
    super.removedFromStage(stage);
  }

  @override
  void boundsChanged() {
    super.boundsChanged();

    // Propagate to the control points too (if we have them).
    _in?.boundsChanged();
    _out?.boundsChanged();
  }

  // TODO: component.path?.stageItem
  @override
  StageItem get soloParent => component.path.stageItem;

  @override
  void drawPoint(Canvas canvas, Rect rect, Paint stroke, Paint fill) {
    canvas.drawOval(rect, stroke);
    canvas.drawOval(rect, fill);
  }

  @override
  Vec2D get translation => component.translation;

  @override
  Mat2D get worldTransform => component.path.worldTransform;
}
