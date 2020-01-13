import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/selectable_item.dart';

import '../stage.dart';
import '../stage_item.dart';

class StageArtboard extends StageItem<Artboard> implements ArtboardDelegate {
  AABB _aabb;

  @override
  bool initialize(Artboard object) {
    if (!super.initialize(object)) {
      return false;
    }
    updateBounds();
    return true;
  }

  @override
  AABB get aabb => _aabb;

  @override
  void markBoundsDirty() {
    stage.debounce(updateBounds);
  }

  void updateBounds() {
    _aabb = AABB.fromValues(component.x, component.y,
        component.x + component.width, component.y + component.height);
    stage?.updateBounds(this);
  }

  // @override
  // void addedToStage(Stage stage) {
  //   super.addedToStage(stage);
  //   updateBounds();
  // }

  @override
  void removedFromStage(Stage stage) {
    super.removedFromStage(stage);
    stage.cancelDebounce(updateBounds);
  }

  @override
  void paint(Canvas canvas) {
    canvas.drawRect(
        Rect.fromLTWH(
            component.x, component.y, component.width, component.height),
        Paint()..color = selectionState.value == SelectionState.none ? Color.fromRGBO(100, 100, 100, 1.0) : Color.fromRGBO(200, 200, 200, 1.0));
  }
}
