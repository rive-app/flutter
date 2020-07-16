import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard_title.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageArtboard extends StageItem<Artboard> implements ArtboardDelegate {
  StageArtboardTitle _title;

  @override
  bool initialize(Artboard object) {
    if (!super.initialize(object)) {
      return false;
    }
    _updateBounds();
    return true;
  }

  @override
  bool get isHoverSelectable =>
      // We can't be selected if we're already the active artboard.
      component.context.backboard?.activeArtboard != component &&
      super.isSelectable;

  @override
  Iterable<StageDrawPass> get drawPasses =>
      [StageDrawPass(draw, order: 0, inWorldSpace: true)];

  @override
  void boundsChanged() => _updateBounds();

  void _updateBounds() {
    aabb = AABB.fromValues(component.x, component.y,
        component.x + component.width, component.y + component.height);
    _title?.boundsChanged();
    // Mark bounds dirty of other stageItems within the artboard.
    component.forEachComponent((component) {
      var stageItem = component.stageItem;
      if (stageItem is BoundsDelegate) {
        (stageItem as BoundsDelegate).boundsChanged();
      }
    });
  }

  @override
  void onSelectedChanged(bool selected, bool notify) {
    if (selected) {
      assert(component.context.backboard != null,
          'backboard should already exist');
      component.context.backboard.activeArtboard = component;
    }
    stage?.markNeedsRedraw();
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
    if (_title != null) {
      stage.removeItem(_title);
    }
    _title = null;
  }

  @override
  void draw(Canvas canvas, StageDrawPass pass) {
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
    
    canvas.save();

    canvas.translate(component.x, component.y);

    // To mitigate Flutter race conditions between advance and paint, we force a
    // component update here (usually this results in a no-op unless advance
    // couldn't be called prior to the stage.draw).
    component.updateComponents();

    // Now draw the actual drawables.
    component.draw(canvas);

    // Get back into stage space.
    canvas.restore();
  }

  @override
  void markNameDirty() => _title?.markNameDirty();
}
