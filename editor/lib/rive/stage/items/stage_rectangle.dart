import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/rectangle.dart';

import '../stage_item.dart';

class StageRectangle extends StageItem<Rectangle> with BoundsDelegate {
  @override
  AABB get aabb => component.shape.bounds;

  @override
  void boundsChanged() {
    assert(stage != null);
    stage.updateBounds(this);
  }
}
