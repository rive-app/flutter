import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/user_path.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageUserPath extends StageItem<UserPath> with BoundsDelegate {
  @override
  AABB get aabb => component.shape.bounds;

  @override
  void boundsChanged() {
    assert(stage != null);
    stage.updateBounds(this);
  }
}