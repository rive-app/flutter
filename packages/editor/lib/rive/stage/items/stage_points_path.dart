import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class StagePointsPath extends StagePath<PointsPath> {
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
}
