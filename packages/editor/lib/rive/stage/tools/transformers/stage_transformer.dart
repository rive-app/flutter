import 'dart:ui';
import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:utilities/tops.dart' as utils;

abstract class StageTransformer {
  bool init(Set<StageItem> items, DragTransformDetails details);
  void advance(DragTransformDetails details);
  void complete();

  void draw(Canvas canvas) {}

  Iterable<T> topComponents<T extends Component>(Iterable<T> items) => utils
      // ignore: unnecessary_cast
      .tops(items as Iterable<Component>)
      .cast<T>()
      .toList(growable: false);
}
