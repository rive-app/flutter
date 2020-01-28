import 'package:rive_core/math/vec2d.dart';
import '../items/stage_artboard.dart';

import 'stage_tool.dart';

class TranslateTool extends StageTool {
  @override
  void endDrag() {
    stage.riveFile.captureJournalEntry();
  }

  @override
  void updateDrag(Vec2D worldMouse) {
    for (final stageItem in selection) {
      if (stageItem is StageArtboard) {
        stageItem.component.x += worldMouseMove[0];
        stageItem.component.y += worldMouseMove[1];
      }
    }
  }
}
