import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageVertex extends StageItem<PathVertex> with BoundsDelegate {
  static const double _vertexRadius = 3;
  static const double _vertexRadiusSelected = 4;
  static const double hitRadiusSquared =
      _vertexRadiusSelected * _vertexRadiusSelected;
  static const double _maxWorldVertexRadius = _vertexRadius / Stage.minZoom;
  double radiusScale = 1;

  @override
  int get drawOrder => 2;

  // Stage vertices don't get automatically added to the stage. They only get
  // added when the path owning them is edited.
  @override
  bool get isAutomatic => false;

  final Vec2D _worldTranslation = Vec2D();

  @override
  bool get showInHierarchy => false;

  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);
    boundsChanged();
  }

  @override
  bool hitHiFi(Vec2D worldMouse) {
    return Vec2D.squaredDistance(worldMouse, _worldTranslation) <=
        hitRadiusSquared / (stage.viewZoom * stage.viewZoom);
  }

  @override
  AABB get aabb => AABB.fromValues(
        _worldTranslation[0] - _maxWorldVertexRadius,
        _worldTranslation[1] - _maxWorldVertexRadius,
        _worldTranslation[0] + _maxWorldVertexRadius,
        _worldTranslation[1] + _maxWorldVertexRadius,
      );

  @override
  void draw(Canvas canvas) {
    var radius = _vertexRadius;
    switch (selectionState.value) {
      case SelectionState.hovered:
      case SelectionState.selected:
        radius = _vertexRadiusSelected;
        break;
      default:
        break;
    }
    final scale = 1 / stage.viewZoom * radiusScale;

    canvas.save();
    canvas.translate(_worldTranslation[0], _worldTranslation[1]);
    canvas.scale(scale);
    canvas.drawCircle(
        Offset.zero, radius, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  @override
  void boundsChanged() {
    if (stage == null) {
      return;
    }
    final origin = component.artboard.originWorld;
    Vec2D.transformMat2D(
        _worldTranslation,
        Vec2D.add(Vec2D(), origin, component.translation),
        component.path.worldTransform);

    stage.updateBounds(this);
  }

  @override
  StageItem get soloParent => component.path.stageItem;
}
