import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/stage_contour_item.dart';

class StagePath extends StageContourItem<PointsPath> {
  @override
  AABB get aabb =>
      component.shape.bounds.translate(component.artboard.originWorld);

  /// A StagePath cannot be directly clicked on in the stage. It can be selected
  /// via the hierarchy. This is because clicking over a path effectively
  /// selects the shape (in the stage).
  @override
  bool get isSelectable => false;
}
