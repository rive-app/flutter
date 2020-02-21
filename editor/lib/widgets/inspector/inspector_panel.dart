import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/inspectable.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/common/custom_expansion_tile.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';
import 'package:rive_editor/widgets/listenable_builder.dart';
import 'package:rive_editor/widgets/theme.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    return Container(
      color: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
      child: ListenableBuilder(
        listenable: rive.selection,
        builder: (context, SelectionContext<SelectableItem> selection, _) {
          if (selection.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: const Text(
                      "No Selection",
                      style: TextStyle(
                        color: ThemeUtils.textWhite,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(height: 10),
                  Container(
                    child: const Text(
                      "Select something to view its properties and options.",
                      style: TextStyle(
                        color: ThemeUtils.textGreyLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          var stageItems =
              selection.items.whereType<StageItem>().toList(growable: false);

          var componentItems = stageItems
              .map<Component>((stageItem) => stageItem.component as Component)
              .toList(growable: false);

          Set<InspectorBase> inspectorItems = {};
          for (final item in stageItems) {
            var inspItems = item.inspectorItems;
            inspectorItems.addAll(inspItems);
          }

          var listItems = <Widget>[];
          for (final inspectorItem in inspectorItems) {
            if (inspectorItem is InspectorGroup) {
              listItems.add(CustomExpansionTile(
                title: Text(inspectorItem.name),
                initiallyExpanded: inspectorItem.isExpanded.value,
                expanded: inspectorItem.isExpanded,
                children: <Widget>[
                  for (final child in inspectorItem.children) ...[
                    if (child is InspectorItem) ...[
                      buildItem(child, componentItems)
                    ]
                  ]
                ],
              ));
            } else if (inspectorItem is InspectorItem) {
              listItems.add(buildItem(inspectorItem, componentItems));
            }
          }

          return ListView(children: listItems);
        },
      ),
    );
  }

  Widget buildItem(InspectorItem item, List<Component> selectedComponents) {
    if (item.propertyKeys.length == 2) {
      return PropertyDual(
        name: item.name,
        objects: selectedComponents,
        propertyKeyA: item.propertyKeys[0],
        propertyKeyB: item.propertyKeys[1],
      );
    }
    if (item.propertyKeys.length == 1) {
      return PropertySingle(
        name: item.name,
        objects: selectedComponents,
        propertyKey: item.propertyKeys[0],
      );
    }
    return Container();
  }
}
