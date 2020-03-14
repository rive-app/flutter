import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/triangle.dart';

import '../stage_item.dart';

class StageTriangle extends StageItem<Triangle> with BoundsDelegate {
  @override
  AABB get aabb =>
      component.shape.bounds.translate(component.artboard.originWorld);

  @override
  void boundsChanged() {
    assert(stage != null);
    stage.updateBounds(this);
  }

  /// A StagePath cannot be directly clicked on in the stage. It can be selected
  /// via the hierarchy. This is because clicking over a path effectively
  /// selects the shape (in the stage).
  @override
  bool get isSelectable => false;
}
