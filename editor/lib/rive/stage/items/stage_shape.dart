import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/shapes/shape.dart';

import '../stage_item.dart';

class StageShape extends StageItem<Shape> with BoundsDelegate {
  @override
  AABB get aabb => component.bounds;

  @override
  void boundsChanged() {
    assert(stage != null);
    stage.updateBounds(this);
  }

  @override
  void paint(Canvas canvas) {
    // Write now the StageShape draws the shape itself, this needs to be moved
    // to the drawable shape component. The only painting the StageShape will do
    // is when the item is selected.
    canvas.drawPath(
        component.uiPath,
        Paint()
          ..color = selectionState.value == SelectionState.none
              ? const Color.fromRGBO(100, 100, 100, 1.0)
              : const Color.fromRGBO(200, 200, 200, 1.0));
  }
}
