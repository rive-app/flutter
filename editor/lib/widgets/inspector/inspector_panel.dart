import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/widgets/common/custom_expansion_tile.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/listenable_builder.dart';
import 'package:rive_editor/widgets/theme.dart';

import 'controller.dart';
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
          var artboards = selection.items
              .whereType<StageArtboard>()
              .map((stageItem) => stageItem.component)
              .toList(growable: false);
          return ValueListenableBuilder<List<InspectorBase>>(
            valueListenable: rive.inspectorController.itemsListenable,
            builder: (_, items, __) => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is InspectorGroup) {
                  return CustomExpansionTile(
                    title: Text(item.name),
                    initiallyExpanded: item.isExpanded.value,
                    expanded: item.isExpanded,
                    children: <Widget>[
                      for (var child in item.children) ...[
                        if (child is InspectorItem) ...[
                          buildItem(child, artboards),
                        ],
                      ]
                    ],
                  );
                }
                if (item is InspectorItem) {
                  return buildItem(item, artboards);
                }
                return Container();
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildItem(InspectorItem item, List<Artboard> artboards) {
    if (item.propertyKeys.length == 2) {
      return PropertyDual(
        name: item.name,
        objects: artboards,
        propertyKeyA: item.propertyKeys[0],
        propertyKeyB: item.propertyKeys[1],
      );
    }
    if (item.propertyKeys.length == 1) {
      return PropertySingle(
        name: item.name,
        objects: artboards,
        propertyKey: item.propertyKeys[0],
      );
    }
    return Container();
  }
}
