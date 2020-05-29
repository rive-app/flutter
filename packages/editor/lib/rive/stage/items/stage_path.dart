import 'dart:ui';

import 'package:rive_core/math/aabb.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/stage_contour_item.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StagePath extends StageContourItem<PointsPath> {
  @override
  AABB get aabb =>
      component.shape.bounds.translate(component.artboard.originWorld);

  /// A StagePath cannot be directly clicked on in the stage. It can be selected
  /// via the hierarchy. This is because clicking over a path effectively
  /// selects the shape (in the stage).
  @override
  bool get isSelectable => false;

  @override
  void onSoloChanged(bool isSolo) {
    for (final vertex in component.vertices) {
      if (isSolo) {
        stage?.addItem(vertex.stageItem);
      } else {
        stage?.removeItem(vertex.stageItem);
      }
    }
  }

  @override
  void draw(Canvas canvas) {
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
