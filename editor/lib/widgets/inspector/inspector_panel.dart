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
import 'package:rive_editor/widgets/tinted_icon.dart';

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
            // Todo: ensure they do not overlap
            var inspItems = item.inspectorItems;
            inspectorItems.addAll(inspItems);
          }

          var listItems = <Widget>[];
          listItems.add(Padding(
            padding:
                const EdgeInsets.only(top: 13, bottom: 11, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (var i = 1; i <= 8; i++)
                  Flexible(
                    flex: 1,
                    child: Container(
                      child: Transform.scale(
                        scale: 0.5,
                        child: TintedIcon(
                          color: RiveTheme.of(context)
                              .textStyles
                              .inspectorPropertyLabel
                              .color,
                          icon: 'align$i',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ));
          listItems.add(InspectorDivider());
          listItems.add(const SizedBox(height: 14));
          for (final inspectorItem in inspectorItems) {
            if (inspectorItem is InspectorGroup) {
              if (inspectorItem.name == null) {
                for (final child in inspectorItem.children) {
                  listItems.add(buildItem(child, componentItems));
                }
                listItems.add(const SizedBox(height: 14));
                listItems.add(InspectorDivider());
              } else {
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
                listItems.add(const SizedBox(height: 14));
                listItems.add(InspectorDivider());
              }
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
    if (item.properties.length == 2) {
      return PropertyDual(
          name: item.name,
          objects: selectedComponents,
          propertyKeyA: item.properties[0].key,
          propertyKeyB: item.properties[1].key,
          labelA: item.properties[0].label,
          labelB: item.properties[1].label,
          linkable: item.linkable);
    }
    if (item.properties.length == 1) {
      return PropertySingle(
        name: item.name,
        objects: selectedComponents,
        propertyKey: item.properties[0].key,
      );
    }
    return Container();
  }
}

class InspectorDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20),
      child: const Divider(
        height: 1,
        color: Color(0xFF444444),
      ),
    );
  }
}
