import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

abstract class StageTransformer {
  bool init(Iterable<StageItem> items, DragTransformDetails details);
  void advance(DragTransformDetails details);
  void complete();
}
