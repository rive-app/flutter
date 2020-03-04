import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageVertex extends StageItem<PathVertex> {

  double radiusScale = 1;

  @override
  AABB get aabb {
    var x = _renderTransform[4];
    var y = _renderTransform[5];
    return AABB.fromValues(x, y, x + 3, y + 3);
  }

  Mat2D _renderTransform;
  Mat2D get renderTransform => _renderTransform;

  PointsPath get path {
    if (component.parent is PointsPath) {
      return component.parent as PointsPath;
    }
    throw CastError();
  }

  @override
  bool initialize(PathVertex component) {
    super.initialize(component);
    final worldTranslation = Vec2D.transformMat2D(
        Vec2D(), component.translation, path.pathTransform);
    _renderTransform = Mat2D.fromTranslation(worldTranslation);
    return true;
  }

  @override
  void paint(Canvas canvas) {
    final rt = _renderTransform;

    canvas.save();
    canvas.transform(rt.mat4);
    final scale = 1 / stage.viewZoom * radiusScale;
    final vecScale = Vec2D.fromValues(scale, scale);
    final matScale = Mat2D.fromScaling(vecScale);
    canvas.transform(matScale.mat4);
    canvas.drawCircle(Offset.zero, 3, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }
}
