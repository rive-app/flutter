import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

import '../rive/hierarchy_tree_controller.dart';
import '../rive/stage/stage_item.dart';
import 'tree_view/drop_item_background.dart';
import 'tree_view/tree_expander.dart';
import 'package:tree_widget/tree_scroll_view.dart';

/// An example tree view, shows how to implement TreeView widget and style it.
class HierarchyTreeView extends StatelessWidget {
  final HierarchyTreeController controller;

  const HierarchyTreeView({
    @required this.controller,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var style = TreeStyle(
      showFirstLine: true,
      padding: const EdgeInsets.all(10),
      lineColor: Colors.grey.shade700,
    );
    return TreeScrollView(
      style: style,
      slivers: [
        TreeView<Component>(
          style: style,
          controller: controller,
          expanderBuilder: (context, item) => Container(
            child: Center(
              child: TreeExpander(
                key: item.key,
                iconColor: Colors.white,
                isExpanded: item.isExpanded,
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade700,
                width: 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(7.5),
              ),
            ),
          ),
          iconBuilder: (context, item) => Container(
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: const BorderRadius.all(
                Radius.circular(2),
              ),
            ),
          ),
          extraBuilder: (context, item, index) => Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(7.5),
              ),
            ),
          ),
          backgroundBuilder: (context, item) =>
              ValueListenableBuilder<DropState>(
            valueListenable: item.dropState,
            builder: (context, dropState, _) =>
                ValueListenableBuilder<SelectionState>(
              builder: (context, selectionState, _) {
                return DropItemBackground(dropState, selectionState);
              },
              valueListenable: item.data.stageItem?.selectionState,
            ),
          ),
          itemBuilder: (context, item) =>
              ValueListenableBuilder<SelectionState>(
            builder: (context, state, _) => Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    // Use CorePropertyBuilder to get notified when the component's
                    // name changes.
                    child: CorePropertyBuilder<String>(
                      object: item.data,
                      propertyKey: ComponentBase.namePropertyKey,
                      builder: (context, name, _) => Renamable(
                        name: name,
                        color: state == SelectionState.selected
                            ? Colors.white
                            : Colors.grey.shade500,
                        onRename: (name) {
                          item.data.name = name;
                          RiveContext.of(context)
                              .file
                              .value
                              .captureJournalEntry();
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(-1, 0),
                    child: Text(
                      "lock",
                      style: TextStyle(
                        fontSize: 13,
                        color: state == SelectionState.selected
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5)
                ],
              ),
            ),
            valueListenable: item.data.stageItem.selectionState,
          ),
        ),
      ],
    );
  }
}
