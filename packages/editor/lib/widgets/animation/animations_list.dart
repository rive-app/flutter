import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/managers/animations_manager.dart';
import 'package:rive_editor/widgets/animation/animation_tree_controller.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rxdart/streams.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

class AnimationsList extends StatefulWidget {
  final AnimationsManager animationManager;

  const AnimationsList({
    @required this.animationManager,
    Key key,
  }) : super(key: key);

  @override
  _AnimationsListState createState() => _AnimationsListState();
}

class _AnimationsListState extends State<AnimationsList> {
  AnimationTreeController _treeController;
  @override
  void initState() {
    _treeController = AnimationTreeController(widget.animationManager);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _treeController.dispose();
  }

  @override
  void didUpdateWidget(AnimationsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationManager != widget.animationManager) {
      _treeController = AnimationTreeController(widget.animationManager);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var style = TreeStyle(
      showFirstLine: false,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      lineColor: RiveTheme.of(context).colors.darkTreeLines,
    );
    return TreeScrollView(
      padding: style.padding,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 3,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ANIMATIONS',
                    style: theme.textStyles.inspectorSectionHeader
                        .copyWith(height: 1),
                  ),
                ),
                TintedIconButton(
                  icon: 'add',
                  onPress: () =>
                      widget.animationManager.create.add(AnimationType.linear),
                )
              ],
            ),
          ),
        ),
        TreeView<ValueStream<AnimationViewModel>>(
          style: style,
          controller: _treeController,
          dragItemBuilder: (context, items, style) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items
                .map(
                  (item) => Text(
                    item.data.value.animation.name,
                    style: theme.textStyles.treeDragItem,
                  ),
                )
                .toList(),
          ),
          expanderBuilder: (context, item, style) => Container(
            child: Center(
              child: TreeExpander(
                key: item.key,
                iconColor: theme.colors.buttonHover,
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
          iconBuilder: (context, item, style) => TintedIcon(
            icon: item.data.value.icon,
            color: theme.colors.inspectorTextColor,
          ),
          backgroundBuilder: (context, item, style) =>
              ValueListenableBuilder<DropState>(
            valueListenable: item.dropState,
            builder: (context, dropState, _) =>
                StreamBuilder<AnimationViewModel>(
              stream: item.data,
              builder: (context, snapshot) => DropItemBackground(
                dropState,
                snapshot.hasData
                    ? snapshot.data.selectionState
                    : SelectionState.none,
                color: theme.colors.animationSelected,
                hoverColor: theme.colors.editorTreeHover,
              ),
            ),
          ),
          itemBuilder: (context, item, style) =>
              StreamBuilder<AnimationViewModel>(
            stream: item.data,
            builder: (context, snapshot) => Expanded(
              child: !snapshot.hasData
                  ? const SizedBox()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          // Use CorePropertyBuilder to get notified when the
                          // component's name changes.
                          child: CorePropertyBuilder<String>(
                            object: snapshot.data.animation,
                            propertyKey: AnimationBase.namePropertyKey,
                            builder: (context, name, _) => Renamable(
                              style: theme.textStyles.inspectorWhiteLabel,
                              name: name,
                              color: snapshot.data.selectionState !=
                                      SelectionState.none
                                  ? theme.colors.activeText
                                  : theme.colors.inspectorTextColor,
                              onRename: (name) {
                                widget.animationManager.rename.add(
                                    RenameAnimationModel(name, snapshot.data));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 5)
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
