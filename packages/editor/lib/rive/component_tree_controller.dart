import 'package:flutter/widgets.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:tree_widget/flat_tree_item.dart';
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

   @override
  List<FlatTreeItem<Component>> onDragStart(
      DragStartDetails details, FlatTreeItem<Component> item) {
    // All items in draw order have a stage item.
    if (!item.data.stageItem.isSelected) {
      file.select(item.data.stageItem);
    }
    // Get inspection set (selected components).
    var inspectionSet = InspectionSet.fromSelection(file, file.selection);

    // Find matching tree items (N.B. that means that if they're not expanded
    // they won't drag, probably ok for now).
    final dragItems = <FlatTreeItem<Component>>[];
    for (final component in inspectionSet.components) {
      final key = ValueKey(component);
      var found = indexLookup[key];
      if (found != null) {
        dragItems.add(flat[found]);
      }
    }

    dragItems.sort((a, b) => a.index.compareTo(b.index));
    
    return dragItems;
  }
}
