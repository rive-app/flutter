import 'package:flutter/widgets.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/hierarchy.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:rive_editor/widgets/tree_view/stage_item_icon.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_widgets/listenable_builder.dart';

/// Left hand panel contains the hierarchy and draw order widgets
class HierarchyPanel extends StatefulWidget {
  @override
  _HierarchyPanelState createState() => _HierarchyPanelState();
}

class _HierarchyPanelState extends State<HierarchyPanel> {
  bool hierarchySelected = true;
  bool hierarchyHovered = false;
  bool drawOrderHovered = false;

  @override
  Widget build(BuildContext context) {
    final file = ActiveFile.of(context);
    var theme = RiveTheme.of(context);
    var backboard = file.backboard;

    return ColoredBox(
      color: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
      child: backboard == null
          ? null
          : ListenableBuilder<Event>(
              listenable: backboard.activeArtboardChanged,
              builder: (context, event, _) {
                var activeArtboard = backboard.activeArtboard;
                return Column(
                  children: <Widget>[
                    if (activeArtboard != null)
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 17),
                            child:
                                StageItemIcon(item: activeArtboard.stageItem),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5, top: 17),
                              child: CorePropertyBuilder<String>(
                                object: activeArtboard,
                                propertyKey: ComponentBase.namePropertyKey,
                                builder: (context, name, _) => Renamable(
                                  name: name,
                                  style: theme.textStyles.hierarchyName,
                                  onRename: (name) {
                                    activeArtboard.name = name;
                                    activeArtboard.context
                                        .captureJournalEntry();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Expanded(
                      child: ValueListenableBuilder<HierarchyTreeController>(
                        valueListenable: file.treeController,
                        builder: (context, controller, _) =>
                            HierarchyTreeView(controller: controller),
                      ),
                    ),
                  ],
                );
              }),
    );
  }
}
