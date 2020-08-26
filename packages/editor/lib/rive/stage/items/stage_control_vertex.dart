import 'dart:ui';

import 'package:rive_core/bones/cubic_weight.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// Stage representation of a control point (in/out) for a cubic vertex.
abstract class StageControlVertex extends StageVertex<CubicVertex> {
  /// The mirrored/detached/asymmetric control point on the other side of the
  /// main vertex.
  StageControlVertex sibling;

  @override
  void drawPoint(Canvas canvas, Rect rect, Paint stroke, Paint fill) {
    canvas.drawRect(rect, stroke);
    canvas.drawRect(rect, fill);
  }

  @override
  double get radiusScale => 1;

  @override
  Mat2D get worldTransform => component.path.pathTransform;

  @override
  StageItem get soloParent => component.path.stageItem;

  double get angle;
  double get length;
}

/// Concrete stage control point for the in handle.
class StageControlIn extends StageControlVertex {
  @override
  Vec2D get translation => component.weight?.inTranslation ?? component.inPoint;

  @override
  set translation(Vec2D value) => component.inPoint = value;

  @override
  double get angle {
    switch (component.coreType) {
      case CubicMirroredVertexBase.typeKey:
        return (component as CubicMirroredVertex).rotation;
      case CubicAsymmetricVertexBase.typeKey:
        return (component as CubicAsymmetricVertex).rotation;
      case CubicDetachedVertexBase.typeKey:
        return (component as CubicDetachedVertex).inRotation;
    }

    return 0;
  }

  @override
  double get length {
    switch (component.coreType) {
      case CubicMirroredVertexBase.typeKey:
        return (component as CubicMirroredVertex).distance;
      case CubicAsymmetricVertexBase.typeKey:
        return (component as CubicAsymmetricVertex).inDistance;
      case CubicDetachedVertexBase.typeKey:
        return (component as CubicDetachedVertex).inDistance;
    }

    return 0;
  }

  @override
  int get weightIndices => component.weight?.inIndices;

  @override
  set weightIndices(int value) {
    assert(component.weight != null);
    component.weight.inIndices = value;
  }

  @override
  int get weights => component.weight?.inValues;

  @override
  set weights(int value) {
    assert(component.weight != null);
    component.weight.inValues = value;
  }

  @override
  void listenToWeightChange(
      bool enable, void Function(dynamic, dynamic) callback) {
    var weight = component.weight;
    if (enable) {
      weight.addListener(CubicWeightBase.inIndicesPropertyKey, callback);
      weight.addListener(CubicWeightBase.inValuesPropertyKey, callback);
    } else {
      weight.removeListener(CubicWeightBase.inIndicesPropertyKey, callback);
      weight.removeListener(CubicWeightBase.inValuesPropertyKey, callback);
    }
  }
}

/// Concrete stage control point for the out handle.
class StageControlOut extends StageControlVertex {
  @override
  Vec2D get translation =>
      component.weight?.outTranslation ?? component.outPoint;

  @override
  set translation(Vec2D value) => component.outPoint = value;

  @override
  double get angle {
    switch (component.coreType) {
      case CubicMirroredVertexBase.typeKey:
        return (component as CubicMirroredVertex).rotation;
      case CubicAsymmetricVertexBase.typeKey:
        return (component as CubicAsymmetricVertex).rotation;
      case CubicDetachedVertexBase.typeKey:
        return (component as CubicDetachedVertex).outRotation;
    }

    return 0;
  }

  @override
  double get length {
    switch (component.coreType) {
      case CubicMirroredVertexBase.typeKey:
        return (component as CubicMirroredVertex).distance;
      case CubicAsymmetricVertexBase.typeKey:
        return (component as CubicAsymmetricVertex).outDistance;
      case CubicDetachedVertexBase.typeKey:
        return (component as CubicDetachedVertex).outDistance;
    }

    return 0;
  }

  @override
  int get weightIndices => component.weight?.outIndices;

  @override
  set weightIndices(int value) {
    assert(component.weight != null);
    component.weight.outIndices = value;
  }

  @override
  int get weights => component.weight?.outValues;

  @override
  set weights(int value) {
    assert(component.weight != null);
    component.weight.outValues = value;
  }

  @override
  void listenToWeightChange(
      bool enable, void Function(dynamic, dynamic) callback) {
    var weight = component.weight;
    if (enable) {
      weight.addListener(CubicWeightBase.outIndicesPropertyKey, callback);
      weight.addListener(CubicWeightBase.outValuesPropertyKey, callback);
    } else {
      weight.removeListener(CubicWeightBase.outIndicesPropertyKey, callback);
      weight.removeListener(CubicWeightBase.outValuesPropertyKey, callback);
    }
  }
}

class StagePathControlLine extends StageItem<CubicVertex> {
  final StageVertex vertex;
  final StageVertex control;
  final Paint linePaint = Paint()..color = const Color(0x80FFFFFF);

  StagePathControlLine(this.vertex, this.control);

  @override
  bool get isSelectable => false;

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 3, inWorldSpace: true)];

  @override
  AABB get aabb => AABB.fromPoints([
        vertex.worldTranslation,
        control.worldTranslation,
      ]);

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
    var inWorld = vertex.worldTranslation;
    var outWorld = control.worldTranslation;
    canvas.drawLine(Offset(inWorld[0], inWorld[1]),
        Offset(outWorld[0], outWorld[1]), linePaint);
  }

  void boundsChanged() => stage?.updateBounds(this);
}
