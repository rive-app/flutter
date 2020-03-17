import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageVertex extends StageItem<PathVertex> {
  static const double _vertexSize = 3;
  double radiusScale = 1;

  @override
  AABB get aabb => AABB
      .fromValues(component.x, component.y, component.x, component.y)
      .translate(component.artboard.originWorld);

  PointsPath get path {
    if (component.parent is PointsPath) {
      return component.parent as PointsPath;
    }
    throw CastError();
  }

  @override
  void paint(Canvas canvas) {
    final origin = component.artboard.originWorld;
    final scale = 1 / stage.viewZoom * radiusScale;

    canvas.save();
    canvas.translate(origin[0] + component.x, origin[1] + component.y);
    canvas.scale(scale);
    canvas.drawCircle(
        Offset.zero, _vertexSize, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }
}
