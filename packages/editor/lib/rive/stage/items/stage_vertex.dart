import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// Abstraction for any stage representation of a vertex (shared by meshes,
/// paths, etc).
abstract class StageVertex<T extends Component> extends StageItem<T>
    with BoundsDelegate {
  static const double _vertexRadius = 3.5;
  static const double _vertexRadiusSelected = 4.5;
  static const double hitRadiusSquared =
      (_vertexRadiusSelected + 2.5) * (_vertexRadiusSelected + 2.5);
  static const double _maxWorldVertexRadius = _vertexRadius / Stage.minZoom;

  double get radiusScale;

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
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 4, inWorldSpace: true)];

  // Stage vertices don't get automatically added to the stage. They only get
  // added when the path owning them is edited.
  @override
  bool isAutomatic(Stage stage) => stage.isValidSoloSelection(this);

  final Vec2D _worldTranslation = Vec2D();
  Vec2D get worldTranslation => _worldTranslation;
  set worldTranslation(Vec2D value);

  @override
  bool get showInHierarchy => false;

  /// Expected to be implemented by the concrete point to return the local
  /// position.
  Vec2D translation;

  /// Expected to be implemented by the concrete point to return the runtime
  /// world transorm (usually artboard space) of the parent (shape/image).
  Mat2D get worldTransform;

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
  void draw(Canvas canvas, StageDrawPass drawPass) {
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
    radius *= radiusScale;

    canvas.save();
    canvas.transform(stage.inverseViewTransform.mat4);
    var screenTranslation =
        Vec2D.transformMat2D(Vec2D(), _worldTranslation, stage.viewTransform);
    canvas.translate(screenTranslation[0].roundToDouble() + 0.5,
        screenTranslation[1].roundToDouble() + 0.5);
    var rect = Rect.fromLTRB(-radius, -radius, radius, radius);
    drawPoint(canvas, rect, drawStroke, drawFill);
    canvas.restore();
  }

  void drawPoint(Canvas canvas, Rect rect, Paint stroke, Paint fill);

  @override
  void boundsChanged() {
    if (stage == null) {
      return;
    }
    final origin = component.artboard.originWorld;
    Vec2D.transformMat2D(_worldTranslation, translation, worldTransform);
    _worldTranslation[0] += origin[0];
    _worldTranslation[1] += origin[1];

    stage.updateBounds(this);
  }
}
