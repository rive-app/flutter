import 'package:flutter/widgets.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/rive_core_field_type.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/draw_order_key_button.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/timeline_color_swatch.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/stage_item_icon.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rive_editor/widgets/ui_strings.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_widget.dart';

class KeyedObjectHierarchy extends StatefulWidget {
  final ScrollController scrollController;
  final KeyedObjectTreeController treeController;
  final bool isPlaying;

  const KeyedObjectHierarchy({
    @required this.scrollController,
    @required this.treeController,
    this.isPlaying = false,
    Key key,
  }) : super(key: key);

  @override
  _KeyedObjectHierarchyState createState() => _KeyedObjectHierarchyState();
}

class _KeyedObjectHierarchyState extends State<KeyedObjectHierarchy> {
  /// Set of selected items
  final _selectedItems = <KeyHierarchyViewModel>{};

  @override
  void initState() {
    widget.treeController.requestVisibility
        .addListener(_ensureKeyedComponentVisible);
    widget.treeController.highlight.addListener(_highlightKeyedComponents);
    super.initState();
  }

  @override
  void dispose() {
    widget.treeController.requestVisibility
        .removeListener(_ensureKeyedComponentVisible);
    widget.treeController.highlight.removeListener(_highlightKeyedComponents);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var style = theme.treeStyles.timeline;

    return TreeScrollView(
      scrollController: widget.scrollController,
      padding: style.padding,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        TreeView<KeyHierarchyViewModel>(
          style: style,
          controller: widget.treeController,
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
              selectionState: _selectedItems.contains(item.data)
                  ? SelectionState.selected
                  : SelectionState.none,
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

  /// Autoscrolls the hierarchy if necessary to ensure that the model's visible
  void _ensureKeyedComponentVisible(KeyHierarchyViewModel model) {
    final key = ValueKey(model);
    final index = widget.treeController.indexLookup[key];

    if (index != null) {
      final itemHeight = RiveTheme.find(context).treeStyles.timeline.itemHeight;

      final firstVisible = (widget.scrollController.offset / itemHeight).ceil();
      final lastVisible = ((widget.scrollController.offset +
                  widget.scrollController.position.viewportDimension -
                  itemHeight) /
              itemHeight)
          .floor();
      if (index < firstVisible || index > lastVisible) {
        widget.scrollController.jumpTo((index * itemHeight)
            .clamp(widget.scrollController.position.minScrollExtent,
                widget.scrollController.position.maxScrollExtent)
            .toDouble());
      }
    }
  }

  /// Highlights the given set of models
  void _highlightKeyedComponents(Set<KeyHierarchyViewModel> models) {
    setState(
      () => _selectedItems
        ..clear()
        ..addAll(models),
    );
  }

  Widget _buildKeyedComponent(BuildContext context, RiveThemeData theme,
      KeyedComponentViewModel model) {
    var component = model.component;
    var displayName = component.timelineName ??
        // TODO: uistring this name?
        RiveCoreContext.objectName(component.coreType);

    if (!component.canRename) {
      return Text(
        displayName,
        style: theme.textStyles.inspectorPropertyLabel,
      );
    }

    return Expanded(
      child: CorePropertyBuilder<String>(
        object: component,
        propertyKey: ComponentBase.namePropertyKey,
        builder: (context, name, _) => Renamable(
          style: theme.textStyles.inspectorPropertyLabel,
          name: name,
          color: theme.colors.hierarchyText,
          editingColor: theme.colors.selectedText,
          onRename: (name) {
            component.name = name;
            component.context.captureJournalEntry();
          },
        ),
      ),
    );
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
    var coreType =
        model.component.context.coreType(model.keyedProperty.propertyKey);
    if (coreType == RiveColorType.instance) {
      switch (model.component.coreType) {
        case SolidColorBase.typeKey:
          return TimelineColorSwatch(
            frozen: widget.isPlaying,
            component: model.component as SolidColor,
            colorPropertyKey: SolidColorBase.colorValuePropertyKey,
          );

          break;

        case GradientStopBase.typeKey:
          return TimelineColorSwatch(
            frozen: widget.isPlaying,
            component: model.component as GradientStop,
            colorPropertyKey: GradientStopBase.colorValuePropertyKey,
          );

          break;
      }
    } else if (coreType == RiveDoubleType.instance) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, left: 9),
        child: SizedBox(
          width: 69,
          child: CoreTextField<double>(
            frozen: widget.isPlaying,
            underlineColor: theme.colors.timelineUnderline,
            objects: [model.component],
            propertyKey: model.keyedProperty.propertyKey,
          ),
        ),
      );
    } else if (model.keyedProperty.propertyKey ==
        DrawableBase.drawOrderPropertyKey) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: DrawOrderKeyButton(
            manager: ActiveFile.of(context).editingAnimationManager.value),
      );
    }
    return const SizedBox();
  }
}
