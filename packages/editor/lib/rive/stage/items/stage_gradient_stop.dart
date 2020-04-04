import 'dart:ui';

import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_editor/rive/stage/items/stage_linear_gradient.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageGradientStop extends StageItem<GradientStop> {
  static const double size = 12;
  static const double radius = size / 2;
  static const double hitRadius = radius + 1;
  static const double hitRadiusSquared = hitRadius * hitRadius;
  static const double selectedRadius = 16 / 2;
  static Paint border = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x40000000);

  static Paint line = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF);

  Paint fill = Paint()..isAntiAlias = false;

  StageGradientInterface _stageGradient;

  @override
  StageItem get inspectorItem =>
      ((component.parent as ShapePaintMutator).shapePaintContainer as Component)
          .stageItem;

  Vec2D _position;
  Offset _offset;

  @override
  bool get isAutomatic => false;

  @override
  int get drawOrder => 3;

  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);

    var gradient = component.parent as core.LinearGradient;
    assert(gradient != null,
        'Parent of a GradientStop must always be a Gradient.');

    var gradientStageItem = gradient.stageItem;
    if (gradientStageItem is StageGradientInterface) {
      _stageGradient = gradientStageItem as StageGradientInterface;
      _stageGradient.addStop(this);
    }
  }

  void update(Vec2D world) {
    _position = Vec2D.clone(world);
    _offset = Offset(_position[0], _position[1]);

    var maxWorldRadius = size / Stage.minZoom / 2;
    aabb = AABB.fromValues(world[0] - maxWorldRadius, world[1] - maxWorldRadius,
        world[0] + maxWorldRadius, world[1] + maxWorldRadius);
  }

  @override
  bool hitHiFi(Vec2D worldMouse) {
    return Vec2D.squaredDistance(worldMouse, _position) <=
        hitRadiusSquared / (stage.viewZoom * stage.viewZoom);
  }

  @override
  void removedFromStage(Stage stage) {
    super.removedFromStage(stage);

    _stageGradient?.removeStop(this);
    _stageGradient = null;
  }

  @override
  void draw(Canvas canvas) {
    var zoom = stage.viewZoom;
    border.strokeWidth = 3 / zoom;
    line.strokeWidth = 1 / zoom;

    var zoomedRadius = (selectionState.value != SelectionState.none
            ? selectedRadius
            : radius) /
        zoom;

    fill.color = component.color;
    canvas.drawCircle(_offset, zoomedRadius, border);
    canvas.drawCircle(_offset, zoomedRadius, fill);
    canvas.drawCircle(_offset, zoomedRadius, line);
  }
}
