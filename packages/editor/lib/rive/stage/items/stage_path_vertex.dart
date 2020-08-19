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
  StagePathControlLine _lineIn, _lineOut;

  StageControlVertex get controlIn => _in;
  StageControlVertex get controlOut => _out;

  @override
  double get radiusScale =>
      component.path.vertices.first == component ? 1.5 : 1;

  bool get hasControlPoints => component is CubicVertex;

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

      _lineIn = StagePathControlLine(this, _in);
      _lineIn.initialize(component as CubicVertex);
      _lineOut = StagePathControlLine(this, _out);
      _lineOut.initialize(component as CubicVertex);

      // Set up sibling relationships.
      _in.sibling = _out;
      _out.sibling = _in;

      stage.addItem(_in);
      stage.addItem(_out);
      stage.addItem(_lineIn);
      stage.addItem(_lineOut);
    }
    super.addedToStage(stage);
  }

  @override
  void removedFromStage(Stage stage) {
    if (hasControlPoints) {
      assert(_in != null);
      stage.removeItem(_in);
      stage.removeItem(_out);
      stage.removeItem(_lineIn);
      stage.removeItem(_lineOut);
      _in = _out = null;
      _lineIn = _lineOut = null;
    }
    super.removedFromStage(stage);
  }

  @override
  void boundsChanged() {
    super.boundsChanged();
    // Propagate to the control points too (if we have them).
    _in?.boundsChanged();
    _out?.boundsChanged();
    // Make sure we trigger this last as it depends on _in/_out positions being
    // updated.
    _lineIn?.boundsChanged();
    _lineOut?.boundsChanged();
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
  set translation(Vec2D value) => component.translation = value;

  @override
  Mat2D get worldTransform => component.path.worldTransform;

  @override
  set worldTranslation(Vec2D value) {
    final origin = component.artboard.originWorld;
    value[0] -= origin[0];
    value[1] -= origin[1];
    component.translation = Vec2D.transformMat2D(
        Vec2D(), value, component.path.inverseWorldTransform);
  }


  @override
  int get weightIndices => component.weightIndices;

  @override
  int get weights => component.weights;
}
