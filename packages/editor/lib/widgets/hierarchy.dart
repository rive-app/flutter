import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/rive_tree_view.dart';
import 'package:rive_editor/widgets/tree_view/stage_item_icon.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_widget.dart';

/// An example tree view, shows how to implement TreeView widget and style it.
class HierarchyTreeView extends StatefulWidget {
  final HierarchyTreeController controller;

  const HierarchyTreeView({
    @required this.controller,
    Key key,
  }) : super(key: key);

  @override
  _HierarchyTreeViewState createState() => _HierarchyTreeViewState();
}

class _HierarchyTreeViewState extends State<HierarchyTreeView> {
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    widget.controller.requestVisibility.addListener(_ensureComponentVisible);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.requestVisibility.removeListener(_ensureComponentVisible);
    super.dispose();
  }

  void _ensureComponentVisible(Component component) {
    var key = ValueKey(component);
    var index = widget.controller.indexLookup[key];

    final theme = RiveTheme.find(context);

    var firstVisible =
        (scrollController.offset / theme.treeStyles.hierarchy.itemHeight)
            .ceil();
    var lastVisible = ((scrollController.offset +
                scrollController.position.viewportDimension -
                theme.treeStyles.hierarchy.itemHeight) /
            theme.treeStyles.hierarchy.itemHeight)
        .floor();
    if (index < firstVisible || index > lastVisible) {
      scrollController.jumpTo((index * theme.treeStyles.hierarchy.itemHeight)
          .clamp(scrollController.position.minScrollExtent,
              scrollController.position.maxScrollExtent)
          .toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    var style = theme.treeStyles.hierarchy;

    return RiveTreeView(
      padding: style.padding,
      scrollController: scrollController,
      slivers: [
        TreeView<Component>(
          style: style,
          controller: widget.controller,
          expanderBuilder: (context, item, style) => Container(
            child: Center(
              child: TreeExpander(
                key: item.key,
                // TODO: when we make the real icons in the icon builder,
                // consider whether we want to abstract coloring the expander to
                // the theme or tree style too.
                iconColor: const Color(0xFFFFFFFF),
                isExpanded: item.isExpanded,
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: style.lineColor,
                width: 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(7.5),
              ),
            ),
          ),
          iconBuilder: (context, item, style) =>
              ValueListenableBuilder<SelectionState>(
            valueListenable: item.data.stageItem?.selectionState,
            builder: (context, state, _) => StageItemIcon(
              item: item.data.stageItem,
              selectionState: state,
            ),
          ),
          backgroundBuilder: (context, item, style) =>
              ValueListenableBuilder<DropState>(
            valueListenable: item.dropState,
            builder: (context, dropState, _) =>
                ValueListenableBuilder<SelectionState>(
              builder: (context, selectionState, _) {
                return DropItemBackground(
                  dropState,
                  selectionState,
                  hoverColor: theme.colors.editorTreeHover,
                );
              },
              valueListenable: item.data.stageItem?.selectionState,
            ),
          ),
          itemBuilder: (context, item, style) =>
              ValueListenableBuilder<SelectionState>(
            builder: (context, state, _) => Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    // Use CorePropertyBuilder to get notified when the
                    // component's name changes.
                    child: CorePropertyBuilder<String>(
                      object: item.data,
                      propertyKey: ComponentBase.namePropertyKey,
                      builder: (context, name, _) => Renamable(
                        name: name,
                        color: state == SelectionState.selected
                            ? theme.colors.selectedText
                            : theme.colors.hierarchyText,
                        onRename: (name) {
                          item.data.name = name;
                          widget.controller.file.core.captureJournalEntry();
                        },
                      ),
                    ),
                  ),
                  // Align(
                  //   alignment: const Alignment(-1, 0),
                  //   child: Text(
                  //     "lock",
                  //     style: TextStyle(
                  //       fontSize: 13,
                  //       color: state == SelectionState.selected
                  //           ? Colors.white
                  //           : Colors.grey.shade500,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 5)
                ],
              ),
            ),
            valueListenable: item.data.stageItem.selectionState,
          ),
          dragItemBuilder: (context, items, style) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items
                .map(
                  (item) => Text(
                    item.data.name,
                    style: theme.textStyles.treeDragItem,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
