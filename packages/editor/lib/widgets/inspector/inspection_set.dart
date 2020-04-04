import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// A pre-filtered set of different inspectable types (intersectingCoreTypes,
/// stageItems, and components) found in the selection that inspectors can chose
/// to act on/modify if they are interested.
class InspectionSet {
  final Set<int> intersectingCoreTypes;
  final Set<StageItem> stageItems;
  final List<Component> components;
  final Backboard backboard;

  InspectionSet(
    this.intersectingCoreTypes,
    this.stageItems,
    this.components,
    this.backboard,
  );

  factory InspectionSet.fromSelection(
      Backboard backboard, SelectionContext<SelectableItem> selection) {
    // Get stageItems from selections.
    final stageItems = <StageItem>{};
    for (final item in selection.items) {
      if (item is StageItem) {
        stageItems.add(item.inspectorItem);
      }
    }
    selection.items.whereType<StageItem>().toList(growable: false);

    // Get all components from stageItems.
    var components = Set<Component>.from(stageItems
        .map<Component>((item) =>
            item.component is Component ? item.component as Component : null)
        .where((item) => item != null)).toList(growable: false);

    if (components.isNotEmpty) {
      // Find the intersection of core types shared across all of the
      // selection.
      Set<int> coreTypes = components.first.coreTypes;
      for (int i = 1; i < components.length; i++) {
        coreTypes = coreTypes.intersection(components[i].coreTypes);
      }
      return InspectionSet(coreTypes, stageItems, components, backboard);
    }

    return InspectionSet({}, stageItems, components, backboard);
  }
}
