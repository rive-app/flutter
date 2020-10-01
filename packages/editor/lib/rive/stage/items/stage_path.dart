import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable_component.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

abstract class StagePath<T extends core.Path> extends StageItem<T>
    with BoundsDelegate, StageTransformableComponent<T> {
  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);
    boundsChanged();
  }

  @override
  void boundsChanged() {
    var artboard = component.artboard;
    aabb = artboard.transformBounds(
        component.preciseComputeBounds(component.pathTransform));

    obb = OBB(
      bounds: component.preciseComputeBounds(
        null,
      ),
      transform: artboard.transform(component.pathTransform),
    );
  }

  /// Do a high fidelity hover hit check against the actual path geometry.
  @override
  bool hitHiFi(Vec2D worldMouse) {
    final origin = component.artboard.originWorld;
    Vec2D localMouse = Vec2D.transformMat2D(
        Vec2D(),
        Vec2D.fromValues(worldMouse[0] - origin[0], worldMouse[1] - origin[1]),
        component.inversePathTransform);

    return component.uiPath.contains(Offset(localMouse[0], localMouse[1]));
  }

  /// A StagePath cannot be directly clicked on in the stage. It can be selected
  /// via the hierarchy. This is because clicking over a path effectively
  /// selects the shape (in the stage).
  @override
  bool get isSelectable => ShortcutAction.deepClick.value;

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    if (selectionState.value == SelectionState.none || !stage.showSelection) {
      return;
    }
    var path = component;
    if (path.pathTransform == null) {
      return;
    }

    canvas.save();
    final origin = component.artboard.originWorld;
    canvas.translate(origin[0], origin[1]);

    // when drawing a path's selection bounds, copy the path so we can transform
    // each point to world such that the stroke isn't deformed by the world
    // transform.

    canvas.drawPath(path.uiPath.transform(path.pathTransform.mat4),
        StageItem.selectedPaint);
    canvas.restore();
  }

  @override
  int compareDrawOrderTo(StageItem other) {
    if (other is StagePath) {
      return component.shape.drawOrder
          .compareTo(other.component.shape.drawOrder);
    } else {
      return super.compareDrawOrderTo(other);
    }
  }
}
