import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/listenable_builder.dart';
import 'package:rive_editor/widgets/theme.dart';

import 'property_dual.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    return Container(
      color: const Color.fromRGBO(50, 50, 50, 1.0),
      child: ListenableBuilder(
        listenable: rive.selection,
        builder: (context, SelectionContext<SelectableItem> selection, _) {
          var artboards = selection.items
              .whereType<StageArtboard>()
              .map((stageItem) => stageItem.component)
              .toList(growable: false);
          if (artboards.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Text(
                      "No Selection",
                      style: TextStyle(
                        color: ThemeUtils.textWhite,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(height: 10.0),
                  Container(
                    child: Text(
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
          return Column(
            children: [
              PropertyDual(
                name: 'Pos',
                objects: artboards,
                propertyKeyA: ArtboardBase.xPropertyKey,
                propertyKeyB: ArtboardBase.yPropertyKey,
              ),
              PropertyDual(
                name: 'Size',
                objects: artboards,
                propertyKeyA: ArtboardBase.widthPropertyKey,
                propertyKeyB: ArtboardBase.heightPropertyKey,
              ),
              // selection. PropertyDual()
            ],
          );
        },
      ),
    );
  }
}
