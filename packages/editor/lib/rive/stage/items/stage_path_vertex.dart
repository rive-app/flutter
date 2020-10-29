import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_control_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_context_menu_launcher.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_editor/widgets/popup/context_popup.dart';

/// Implementation of StageVertex for CubicVertex and StraightVertex.
class StagePathVertex extends StageVertex<PathVertex>
    with StageContextMenuLauncher {
  StageControlVertex _in, _out;
  StagePathControlLine _lineIn, _lineOut;

  StageControlVertex get controlIn => _in;
  StageControlVertex get controlOut => _out;

  @override
  double get radiusScale => 1;

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

      // Set up control / vertex relationships
      _in.vertex = this;
      _out.vertex = this;

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

  @override
  StageItem get soloParent => component.path.stageItem;

  WindingArrow _windingArrow;

  @override
  void drawPoint(Canvas canvas, Rect rect, Paint stroke, Paint fill) {
    var drawWindingArrow = component.path.vertices.first == component;
    if (drawWindingArrow) {
      if (_windingArrow?.size != rect) {
        _windingArrow = WindingArrow(rect);
      }
      var path = _windingArrow.uiPath;

      canvas.save();
      canvas.scale(radiusScale);
      double angle = 0;
      if (component is StraightVertex) {
        var vertices = component.path.vertices;
        var index = vertices.indexOf(component);
        if (index != -1 && vertices.length > 1) {
          var next = vertices[(index + 1) % vertices.length];
          var diff =
              Vec2D.subtract(Vec2D(), next.translation, component.translation);
          angle = atan2(diff[1], diff[0]);
        }
      } else {
        var cubic = component as CubicVertex;
        var diff =
            Vec2D.subtract(Vec2D(), cubic.outPoint, component.translation);
        angle = atan2(diff[1], diff[0]);
      }
      canvas.rotate(angle);
      canvas.drawPath(path, stroke);
      canvas.drawPath(path, fill);
      canvas.restore();
    } else {
      canvas.drawOval(rect, stroke);
      canvas.drawOval(rect, fill);
    }
  }

  @override
  Vec2D get translation =>
      component.weight?.translation ?? component.translation;

  @override
  set translation(Vec2D value) => component.translation = value;

  @override
  Mat2D get worldTransform => component.path.pathTransform;

  @override
  int get weightIndices => component.weight?.indices;

  @override
  set weightIndices(int value) {
    assert(component.weight != null);
    component.weight.indices = value;
  }

  @override
  int get weights => component.weight?.values;

  @override
  set weights(int value) {
    assert(component.weight != null);
    component.weight.values = value;
  }

  @override
  List<PopupContextItem> get contextMenuItems {
    if (component.path is PointsPath) {
      var path = component.path as PointsPath;
      return [
        PopupContextItem(
          'Make First Vertex',
          select: () {
            path.makeFirst(component);
            path.context.captureJournalEntry();
          },
        ),
      ];
    }
    return null;
  }
}

class WindingArrow extends core.Path {
  static final Mat2D _identity = Mat2D();
  final Rect size;

  WindingArrow(this.size);

  @override
  Mat2D get inversePathTransform => _identity;

  @override
  bool get isClosed => true;

  @override
  Mat2D get pathTransform => _identity;

  @override
  List<PathVertex> get vertices => [
        StraightVertex()
          ..x = -size.width / 2
          ..y = -size.height / 2
          ..radius = 0.5,
        StraightVertex()
          ..x = size.width / 2
          ..y = 0
          ..radius = 0.5,
        StraightVertex()
          ..x = -size.width / 2
          ..y = size.height / 2
          ..radius = 0.5
      ];
}
