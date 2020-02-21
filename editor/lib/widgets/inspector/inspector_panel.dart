import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/inspectable.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/widgets/common/color_picker.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/common/custom_expansion_tile.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/listenable_builder.dart';
import 'package:rive_editor/widgets/theme.dart';

import 'properties/dual.dart';
import 'properties/single.dart';

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

          var stageItems = selection.items
              .whereType<StageItem>()
              .map<Component>((stage_item) => stage_item.component as Component)
              .toList(growable: false);
          return ValueListenableBuilder<Set<InspectorBase>>(
            valueListenable: rive.inspectorController.itemsListenable,
            builder: (_, items, __) => Column(
              children: <Widget>[
                RaisedButton(
                  child: const Text('Color Picker'),
                  onPressed: () {
                    showDialog<Color>(
                      context: context,
                      builder: (context) {
                        return Center(
                          child: Container(
                            width: 210.0,
                            child: RiveColorPicker(),
                          ),
                        );
                      },
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items.toList()[index];
                      if (item is InspectorGroup) {
                        return CustomExpansionTile(
                          title: Text(item.name),
                          initiallyExpanded: item.isExpanded.value,
                          expanded: item.isExpanded,
                          children: <Widget>[
                            for (var child in item.children) ...[
                              if (child is InspectorItem) ...[
                                buildItem(child, stageItems),
                              ],
                            ]
                          ],
                        );
                      }
                      if (item is InspectorItem) {
                        return buildItem(item, stageItems);
                      }
                      return Container();
                    },
                  ),
                ),
              ],
            ),
          );
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
