import 'package:flutter/widgets.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_core_field_type.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/timeline_color_swatch.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/stage_item_icon.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rive_editor/widgets/ui_strings.dart';
import 'package:rive_widgets/nullable_listenable_builder.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_widget.dart';
import 'package:utilities/restorer.dart';

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

  Restorer _visListenerRestorer;
  Restorer _highlightListenerRestorer;
  @override
  void initState() {
    _visListenerRestorer = widget.treeController.requestVisibility
        .listen(_ensureKeyedComponentVisible);
    _highlightListenerRestorer =
        widget.treeController.highlight.listen(_highlightKeyedComponents);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant KeyedObjectHierarchy oldWidget) {
    // The treecontroller can change while the widget is mounted (swapping
    // active animation in the animations list does this). We need to cancel and
    // resubscribe.
    if (oldWidget.treeController != widget.treeController) {
      _visListenerRestorer.restore();
      _visListenerRestorer = widget.treeController.requestVisibility
          .listen(_ensureKeyedComponentVisible);
      _highlightListenerRestorer.restore();
      _highlightListenerRestorer =
          widget.treeController.highlight.listen(_highlightKeyedComponents);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _visListenerRestorer.restore();
    _highlightListenerRestorer.restore();
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
          backgroundBuilder: (context, item, style) =>
              NullableValueListenableBuilder<SelectionState>(
            builder: (context, selectionState, _) {
              if (selectionState == null) {
                return const SizedBox();
              }
              switch (selectionState) {
                case SelectionState.hovered:
                case SelectionState.selected:
                  return Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: SelectionBorder(
                      // child: child,
                      color: selectionState == SelectionState.hovered
                          ? theme.colors.timelineTreeBackgroundHover
                          : theme.colors.timelineTreeBackgroundSelected,
                      roundRight: false,
                    ),
                  );
                default:
                  return const SizedBox();
              }
            },
            valueListenable: item.data.selectionState,
          ),
          itemBuilder: (context, item, style) {
            var data = item.data;
            Widget widget;
            if (data is KeyedComponentViewModel) {
              widget = _buildKeyedComponent(context, theme, data);
            } else if (data is KeyedGroupViewModel) {
              widget = _buildKeyedGroup(context, theme, data);
            } else if (data is KeyedPropertyViewModel) {
              widget = _buildKeyedProperty(context, theme, data);
            }
            return widget == null
                ? const SizedBox()
                : Expanded(
                    child: Padding(
                      child: widget,
                      padding: const EdgeInsets.only(
                        right: 19,
                      ),
                    ),
                  );
          },
        ),
      ],
    );
  }

  /// Autoscrolls the hierarchy if necessary to ensure that the model's visible
  void _ensureKeyedComponentVisible(KeyHierarchyViewModel model) {
    // Don't scroll to the keyed component if the KeyFrameManager is currently
    // manipulating the selection.
    if (ActiveFile.find(context).keyFrameManager.value.isChangingSelection) {
      return;
    }
    
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

    return CorePropertyBuilder<String>(
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
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: IgnorePointer(
            child: Text(
              UIStrings.of(context).withKey(model.label),
              style: theme.textStyles.inspectorPropertyLabel,
            ),
          ),
        ),
        if (model.subLabel != null)
          IgnorePointer(
            child: Text(
              UIStrings.of(context).withKey(model.subLabel),
              style: theme.textStyles.animationSubLabel,
            ),
          ),
        _buildKeyedPropertyEditor(context, theme, model),
      ],
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
    }
    return const SizedBox();
  }
}
