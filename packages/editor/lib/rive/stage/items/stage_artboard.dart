import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_editor/rive/image_cache.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard_title.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageArtboard extends StageItem<Artboard>
    implements ArtboardDelegate, StageTransformable {
  StageArtboardTitle _title;
  DpiImage _gridImage;

  final _boundsChangedEvent = Event();

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
  void boundsChanged() {
    _boundsChangedEvent.notify();
    _updateBounds();
  }

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
      stage.debounce(activate);
    }
    stage?.markNeedsRedraw();
  }

  void activate() {
    assert(
        component.context.backboard != null, 'backboard should already exist');
    component.context.backboard.activeArtboard = component;
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

    _gridImage = DpiImage(
        cache: stage.file.rive.imageCache,
        loaded: () {
          stage?.markNeedsRedraw();
        },
        filenameFor: (dpi) {
          var size = dpi == 1 ? 1 : 2;
          return 'assets/images/artboard_bg_${size}x.png';
        });
  }

  @override
  void removedFromStage(Stage stage) {
    stage.cancelDebounce(activate);
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

    // Draw the artboard backround.
    if (component.isTranslucent) {
      Image image = _gridImage.image;
      if (image != null) {
        var identity = Mat2D();
        var gridPaint = Paint()
          ..shader = ImageShader(
              image, TileMode.repeated, TileMode.repeated, identity.mat4);
        canvas.drawPath(component.path, gridPaint);
      }
    }

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

  @override
  Mat2D get renderTransform => component.transform(component.worldTransform);

  @override
  Mat2D get worldTransform => component.worldTransform;

  @override
  Listenable get worldTransformChanged => _boundsChangedEvent;

  @override
  int get transformFlags => TransformFlags.x | TransformFlags.y;
}
