import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:utilities/iterable.dart';

import 'stage/stage_item.dart';

/// A tree controller with backing items of type Component. Facilitates
/// selecting them in context of the Rive file.
abstract class ComponentTreeController extends TreeController<Component> {
  OpenFileContext get file;

  @override
  bool get isRangeSelecting => file.selectionMode == SelectionMode.range;

  @override
  void selectTreeItem(Component item) {
    if (item.stageItem != null) {
      file.select(item.stageItem);
    }
  }

  @override
  void selectMultipleTreeItems(Iterable<Component> items) {
    var select = items.mapWhereType<StageItem>((item) => item.stageItem);
    if (select.isEmpty) {
      return;
    }
    file.selection.selectMultiple(select);
  }

  @override
  Component get rangeSelectionPivot {
    if (file.selection.items.isNotEmpty) {
      var pivot = file.selection.items.first;
      if (pivot is StageItem<Component>) {
        return pivot.component;
      }
    }
    return null;
  }
}
