import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageVertex extends StageItem<PathVertex> with BoundsDelegate {
  static const double _vertexRadius = 3.5;
  static const double _vertexRadiusSelected = 4.5;
  static const double hitRadiusSquared =
      (_vertexRadiusSelected + 1.5) * (_vertexRadiusSelected + 1.5);
  static const double _maxWorldVertexRadius = _vertexRadius / Stage.minZoom;

  double get radiusScale =>
      component.path.vertices.first == component ? 1.5 : 1;

  static final Paint stroke = Paint()
    ..style = PaintingStyle.stroke
    // Stroke is 3 so 1.5 sticks out when we draw fill over it.
    ..strokeWidth = 3
    ..color = const Color(0x26000000);
  static final Paint fill = Paint()..color = const Color(0xFFFFFFFF);

  static final Paint selectedStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFFFFFFF);
  static final Paint selectedFill = Paint()..color = const Color(0xFF00BBFF);

  @override
  int get drawOrder => 3;

  // Stage vertices don't get automatically added to the stage. They only get
  // added when the path owning them is edited.
  @override
  bool isAutomatic(Stage stage) => stage.isValidSoloSelection(this);

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
    var squaredRadiusScale = radiusScale;
    squaredRadiusScale *= squaredRadiusScale;
    return Vec2D.squaredDistance(worldMouse, _worldTranslation) <=
        hitRadiusSquared *
            squaredRadiusScale /
            (stage.viewZoom * stage.viewZoom);
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
    Paint drawStroke, drawFill;
    var radius = _vertexRadius;
    switch (selectionState.value) {
      case SelectionState.hovered:
        drawStroke = stroke;
        drawFill = fill;
        radius = _vertexRadiusSelected;
        break;
      case SelectionState.selected:
        drawStroke = selectedStroke;
        drawFill = selectedFill;
        radius = _vertexRadiusSelected;
        break;
      default:
        drawStroke = stroke;
        drawFill = fill;
        break;
    }
    radius *=  radiusScale;

    canvas.save();
    canvas.transform(stage.inverseViewTransform.mat4);
    var screenTranslation =
        Vec2D.transformMat2D(Vec2D(), _worldTranslation, stage.viewTransform);
    canvas.translate(screenTranslation[0].roundToDouble() + 0.5,
        screenTranslation[1].roundToDouble() + 0.5);
    // canvas.scale(scale);
    var rect = Rect.fromLTRB(-radius, -radius, radius, radius);
    canvas.drawOval(rect, drawStroke);
    canvas.drawOval(rect, drawFill);
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

  // TODO: component.path?.stageItem
  @override
  StageItem get soloParent => component.path.stageItem;
}
