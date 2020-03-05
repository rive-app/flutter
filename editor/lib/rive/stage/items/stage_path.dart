import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/stage_contour_item.dart';

class StagePath extends StageContourItem<PointsPath> {
  @override
  AABB get aabb => component.shape.bounds;
}
