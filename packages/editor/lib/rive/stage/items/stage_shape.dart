import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/stage/stage_contour_item.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StageShape extends StageContourItem<Shape> {  
  // We could make an artboardBounds getter on the component, but we should try
  // to keep the component's logic to what will actually be necessary in a
  // runtime (this may not be entirely possible, but this one is definitely not
  // necessary at runtime).
  @override
  AABB get aabb => component.bounds.translate(component.artboard.originWorld);

  /// Do a high fidelity hover hit check against the actual path geometry.
  @override
  bool hitHiFi(Vec2D worldMouse) {
    final origin = component.artboard.originWorld;
    return component.pathComposer.uiPath
        .contains(Offset(worldMouse[0] - origin[0], worldMouse[1] - origin[1]));
  }

  @override
  void paint(Canvas canvas) {
    if (selectionState.value == SelectionState.none) {
      return;
    }
    assert(component.pathComposer != null);
    // Right now the StageShape draws the shape itself, this needs to be moved
    // to the drawable shape component. The only painting the StageShape will do
    // is when the item is selected.
    canvas.save();
    final origin = component.artboard.originWorld;
    canvas.translate(origin[0], origin[1]);
    canvas.drawPath(component.pathComposer.uiPath, StageItem.selectedPaint);
    canvas.restore();
  }
}
