import 'package:flutter/widgets.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/draw_order_key_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/stage_item_icon.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rive_editor/widgets/ui_strings.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_widget.dart';

class KeyedObjectHierarchy extends StatelessWidget {
  final ScrollController scrollController;
  final KeyedObjectTreeController treeController;

  const KeyedObjectHierarchy({
    @required this.scrollController,
    @required this.treeController,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var style = theme.treeStyles.timeline;

    return TreeScrollView(
      scrollController: scrollController,
      padding: style.padding,
      slivers: [
        TreeView<KeyHierarchyViewModel>(
          style: style,
          controller: treeController,
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
          iconBuilder: (context, item, style) {
            if (item.data is! KeyedComponentViewModel) {
              return null;
            }
            var viewModel = item.data as KeyedComponentViewModel;
            if (viewModel.component.stageItem == null) {
              return null;
            }
            return StageItemIcon(
              item: (item.data as KeyedComponentViewModel).component.stageItem,
            );
          },
          backgroundBuilder: (context, item, style) => DropItemBackground(
            DropState.none,
            SelectionState.none,
            color: theme.colors.animationSelected,
            hoverColor: theme.colors.editorTreeHover,
          ),
          itemBuilder: (context, item, style) {
            var data = item.data;
            if (data is KeyedComponentViewModel) {
              return _buildKeyedComponent(context, theme, data);
            } else if (data is KeyedGroupViewModel) {
              return _buildKeyedGroup(context, theme, data);
            } else if (data is KeyedPropertyViewModel) {
              return _buildKeyedProperty(context, theme, data);
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildKeyedComponent(BuildContext context, RiveThemeData theme,
      KeyedComponentViewModel model) {
    return Text(
      model.component.name,
      style: theme.textStyles.inspectorWhiteLabel,
    );
    // TODO: make component names renamable in the timeline
    // return Renamable(
    //   style: theme.textStyles.inspectorWhiteLabel,
    //   name: model.component.name,
    //   color: theme.colors.inspectorTextColor,
    //   onRename: (name) {},
    // );
  }

  Widget _buildKeyedGroup(
      BuildContext context, RiveThemeData theme, KeyedGroupViewModel model) {
    return Text(
      UIStrings.of(context).withKey(model.label),
      style: theme.textStyles.inspectorPropertyLabel,
    );
  }

  Widget _buildKeyedProperty(
      BuildContext context, RiveThemeData theme, KeyedPropertyViewModel model) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              UIStrings.of(context).withKey(model.label),
              style: theme.textStyles.inspectorPropertyLabel,
            ),
          ),
          if (model.subLabel != null)
            Text(
              UIStrings.of(context).withKey(model.subLabel),
              style: theme.textStyles.animationSubLabel,
            ),
          _buildKeyedPropertyEditor(context, theme, model),
        ],
      ),
    );
  }

  Widget _buildKeyedPropertyEditor(
      BuildContext context, RiveThemeData theme, KeyedPropertyViewModel model) {
    switch (model.keyedProperty.propertyKey) {
      case DrawableBase.drawOrderPropertyKey:
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: DrawOrderKeyButton(
              manager: ActiveFile.of(context).editingAnimationManager.value),
        );
        break;
      default:
        return Padding(
          padding: const EdgeInsets.only(top: 2, left: 9),
          child: SizedBox(
            width: 69,
            child: CoreTextField<double>(
              underlineColor: theme.colors.timelineUnderline,
              objects: [model.component],
              propertyKey: model.keyedProperty.propertyKey,
              converter: TranslationValueConverter.instance,
            ),
          ),
        );
    }
  }
}
