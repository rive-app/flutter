import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard_title.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';


class StageArtboard extends StageItem<Artboard> implements ArtboardDelegate {
  AABB _aabb;
  StageArtboardTitle _title;

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
  int get drawOrder => 0;

  @override
  void markBoundsDirty() {
    stage?.debounce(updateBounds);
    _title?.markBoundsDirty();
    // Mark bounds dirty of other stageItems within the artboard.
    component.forEachComponent((component) {
      var stageItem = component.stageItem;
      if (stageItem is BoundsDelegate) {
        (stageItem as BoundsDelegate).boundsChanged();
      }
    });
  }

  void updateBounds() {
    _aabb = AABB.fromValues(component.x, component.y,
        component.x + component.width, component.y + component.height);
    stage?.updateBounds(this);
  }

  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);
    var title = StageArtboardTitle(this);
    if (title.initialize(component)) {
      _title = title;
      stage.addItem(title);
    }
  }

  @override
  void removedFromStage(Stage stage) {
    super.removedFromStage(stage);
    stage.cancelDebounce(updateBounds);
    _title?.removedFromStage(stage);
    _title = null;
  }

  @override
  void draw(Canvas canvas) {
    if (selectionState.value != SelectionState.none) {
      canvas.drawRect(
        Rect.fromLTWH(
          component.x,
          component.y,
          component.width,
          component.height,
        ),
        StageItem.selectedPaint,
      );
    }

    // Get into artboard's world space. This is because the artboard draws
    // components in the artboard's space (in component lingo we call this world
    // space). The artboards themselves are drawn in the editor's world space,
    // which is the world space that is used by stageItems. This is a little
    // confusing and perhaps we should find a better wording for the transform
    // spaces. We used "world space" in components as that's the game engine
    // ratified way of naming the top-most transformation. Perhaps we should
    // rename those to artboardTransform and worldTransform is only reserved for
    // stageItems? The other option is to stick with 'worldTransform' in
    // components and use 'editor or stageTransform' for stageItems.
    var originWorld = component.originWorld;

    canvas.save();

    canvas.translate(originWorld[0], originWorld[1]);

    // Now draw the actual drawables.
    component.draw(canvas);

    // Get back into stage space.
    canvas.restore();
  }

  @override
  void markNameDirty() => _title?.markNameDirty();
}
