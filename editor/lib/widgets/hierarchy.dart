import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import '../rive/stage/stage_item.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';
import 'package:rive_core/selectable_item.dart';
import '../rive/hierarchy_tree_controller.dart';
import 'tree_view/drop_item_background.dart';
import 'tree_view/tree_expander.dart';

/// An example tree view, shows how to implement TreeView widget and style it.
class HierarchyTreeView extends StatelessWidget {
  final HierarchyTreeController controller;

  const HierarchyTreeView({Key key, @required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TreeView<Component>(
      style: TreeStyle(
        showFirstLine: true,
        padding: const EdgeInsets.all(10),
        lineColor: Colors.grey.shade700,
      ),
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
      backgroundBuilder: (context, item) => ValueListenableBuilder<DropState>(
        valueListenable: item.dropState,
        builder: (context, dropState, _) =>
            ValueListenableBuilder<SelectionState>(
          builder: (context, selectionState, _) {
            return DropItemBackground(dropState, selectionState);
          },
          valueListenable: item.data.stageItem?.selectionState,
        ),
      ),
      itemBuilder: (context, item) => ValueListenableBuilder<SelectionState>(
        builder: (context, state, _) => Expanded(
          child: Row(
            children: [
              Expanded(
                child: IgnorePointer(
                  child: Text(
                    item.data.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: state == SelectionState.selected
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              Text(
                "lock",
                style: TextStyle(
                  fontSize: 13,
                  color: state == SelectionState.selected
                      ? Colors.white
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 5)
            ],
          ),
        ),
        valueListenable: item.data.stageItem.selectionState,
      ),
    );
  }
}
