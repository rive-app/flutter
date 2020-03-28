import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

abstract class StageContourItem<T> extends StageItem<T> with BoundsDelegate {
  bool showContour = false;

  @override
  void boundsChanged() {
    assert(stage != null, '$this cannot have null stage');
    stage.updateBounds(this);
  }
}