import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/artboard.dart';

import '../stage_item.dart';

class StageArtboard extends StageItem<Artboard> implements ArtboardDelegate {
  AABB _aabb;

  @override
  bool initialize(Artboard object) {
    if (!super.initialize(object)) {
      return false;
    }
    object.delegate = this;
    return true;
  }

  @override
  AABB get aabb => null;

  @override
  void markBoundsDirty() {
      // TODO: figure out how to debounce this for next stage render.
  }
}
