import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_expandable.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable_component.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageShape extends StageItem<Shape>
    with
        BoundsDelegate,
        StageTransformableComponent<Shape>,
        StageExpandable<Shape> {
  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);
    computeBounds();
  }

  @override
  bool get isHoverSelectable => !isExpanded;

  @override
  StageItem get selectionTarget => ShortcutAction.deepClick.value
      ? this
      : StageExpandable.findNonExpanded(this);

  /// Do a high fidelity hover hit check against the actual path geometry.
  @override
  bool hitHiFi(Vec2D worldMouse) {
    final origin = component.artboard.originWorld;
    return worldPath
        .contains(Offset(worldMouse[0] - origin[0], worldMouse[1] - origin[1]));
  }

  // The path composer will only build the type of path that is necessary for
  // runtime rendering. If that doesn't include a world path, then we need to
  // get one from the provided local path. There's a bit of a dance between
  // PathComposer and Shape for when and how PathComposer builds these paths,
  // see the respective update functions of each to fully graps the nuances. It
  // basically boild down to whether there are strokes that want to be affected
  // by their transform or not.
  Path get worldPath => component.fillInWorld
      ? component.pathComposer.worldPath
      : component.pathComposer.localPath
          .transform(component.worldTransform.mat4);

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    if (selectionState.value == SelectionState.none || !stage.showSelection) {
      return;
    }
    assert(component.pathComposer != null);
    // Right now the StageShape draws the shape itself, this needs to be moved
    // to the drawable shape component. The only painting the StageShape will do
    // is when the item is selected.
    canvas.save();
    final origin = component.artboard.originWorld;
    canvas.translate(origin[0], origin[1]);
    canvas.drawPath(worldPath, StageItem.selectedPaint);

    canvas.restore();
  }

  @override
  void removedFromStage(Stage stage) {
    cancelBoundsChanged();
    super.removedFromStage(stage);
  }

  @override
  int compareDrawOrderTo(StageItem other) {
    if (other is StageShape) {
      // check drawable order
      return component.drawOrder.compareTo(other.component.drawOrder);
    } else {
      return super.compareDrawOrderTo(other);
    }
  }

  @override
  void onSoloChanged(bool isSolo) {
    for (final path in component.paths) {
      path.stageItem.onSoloChanged(isSolo);
    }
  }
}
