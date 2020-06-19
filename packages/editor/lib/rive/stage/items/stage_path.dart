import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/path.dart' as core;
import 'package:rive_editor/rive/stage/stage_drawable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

abstract class StagePath<T extends core.Path> extends StageItem<T>
    with BoundsDelegate {
  @override
  void boundsChanged() {
    var artboard = component.artboard;
    aabb = artboard.transformBounds(component.preciseComputeBounds(
        component.renderVertices, component.worldTransform));

    var parent = component.parent as Node;
    var toParentTransform = Mat2D();
    if (!Mat2D.invert(toParentTransform, parent.worldTransform)) {
      Mat2D.identity(toParentTransform);
    }

    obb = OBB(
      bounds: component.preciseComputeBounds(
        component.renderVertices,
        null,
      ),
      transform: component.pathTransform,
    );
  }

  /// A StagePath cannot be directly clicked on in the stage. It can be selected
  /// via the hierarchy. This is because clicking over a path effectively
  /// selects the shape (in the stage).
  @override
  bool get isSelectable => false;

  @override
  void draw(Canvas canvas, StageDrawPass drawPass) {
    if (selectionState.value == SelectionState.none || !stage.showSelection) {
      return;
    }
    canvas.save();
    final origin = component.artboard.originWorld;
    canvas.translate(origin[0], origin[1]);

    var path = component;
    canvas.transform(path.pathTransform?.mat4);

    canvas.drawPath(path.uiPath, StageItem.selectedPaint);
    canvas.restore();
  }
}
