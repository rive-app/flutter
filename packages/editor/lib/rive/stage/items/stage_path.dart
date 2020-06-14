import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StagePath extends StageItem<PointsPath> with BoundsDelegate {
  @override
  void boundsChanged() {
    aabb = component.shape.bounds.translate(component.artboard.originWorld);
  }

  /// A StagePath cannot be directly clicked on in the stage. It can be selected
  /// via the hierarchy. This is because clicking over a path effectively
  /// selects the shape (in the stage).
  @override
  bool get isSelectable => false;

  @override
  void onSoloChanged(bool isSolo) {
    for (final vertex in component.vertices) {
      var stageItem = vertex.stageItem;
      if (stageItem == null) {
        continue;
      }
      if (isSolo) {
        stage?.addItem(stageItem);
      } else {
        stage?.removeItem(stageItem);
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
