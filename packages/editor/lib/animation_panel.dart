import 'dart:async';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/managers/animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/common/animated_factor_builder.dart';
import 'package:rive_editor/widgets/common/fractional_intrinsic_height.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

/// Container for the animation panel that allows it to slide up from the bottom
/// when animation mode is activated.
class AnimationPanel extends StatefulWidget {
  @override
  _AnimationPanelState createState() => _AnimationPanelState();
}

class _AnimationPanelState extends State<AnimationPanel>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    var activeFile = ActiveFile.of(context);
    return ValueListenableBuilder(
      valueListenable: activeFile.mode,
      child: _AnimationPanelContents(),
      builder: (context, EditorMode mode, child) {
        return AnimatedFactorBuilder(
          child: child,
          factor: mode == EditorMode.animate ? 1 : 0,
          builder: (context, factor, child) => FractionalIntrinsicHeight(
            heightFactor: factor,
            child: ResizePanel(
              hitSize: 10,
              direction: ResizeDirection.vertical,
              side: ResizeSide.start,
              min: 235,
              max: 500,
              child: _PanelShadow(
                show: factor > 0,
                // Don't add the animation panel contents to the layout if we're
                // not showing the panel at all, save some cycles.
                child: factor != 0 ? child : const SizedBox(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PanelShadow extends StatelessWidget {
  final bool show;
  final Widget child;

  const _PanelShadow({
    Key key,
    this.show,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      children: [
        if (show)
          Positioned(
            top: -10,
            height: 10,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _PanelShadowPainter(),
            ),
          ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _PanelShadowPainter extends CustomPainter {
  final _paint = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, 10),
      [
        const Color(0x00000000),
        const Color(0x1A000000),
      ],
    );
  @override
  bool shouldRepaint(_PanelShadowPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _paint);
  }
}

class _AnimationPanelContents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var animationManager = AnimationProvider.of(context);
    return ColoredBox(
      color: theme.colors.animationPanelBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 236,
            child: ColoredBox(
              color: theme.colors.tabBackground,
              child: animationManager == null
                  ? const SizedBox()
                  : AnimationHierarchyView(
                      animationManager: animationManager,
                    ),
            ),
          ),
          // Placeholder for timeline and curve editor.
          const Expanded(
            child: SizedBox(),
          ),
          const SizedBox(width: 200),
        ],
      ),
    );
  }
}

class AnimationTreeController
    extends TreeController<ValueStream<AnimationViewModel>> {
  final AnimationManager animationManager;
  StreamSubscription<Iterable<ValueStream<AnimationViewModel>>> _subscription;

  AnimationTreeController(this.animationManager) : super([]) {
    _subscription = animationManager.animations.listen(_animationsChanged);
  }

  void _animationsChanged(
      Iterable<ValueStream<AnimationViewModel>> animations) {
    data = animations.toList();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    cancelDebounce(flatten);
  }

  FlatTreeItem<ValueStream<AnimationViewModel>> _previousExcluding(
      FlatTreeItem<ValueStream<AnimationViewModel>> target,
      List<FlatTreeItem<ValueStream<AnimationViewModel>>> items) {
    for (var item = target.prev; item != null; item = item.prev) {
      if (!items.contains(item)) {
        return item;
      }
    }
    return null;
  }

  FlatTreeItem<ValueStream<AnimationViewModel>> _nextExcluding(
      FlatTreeItem<ValueStream<AnimationViewModel>> target,
      List<FlatTreeItem<ValueStream<AnimationViewModel>>> items) {
    for (var item = target.next; item != null; item = item.next) {
      if (!items.contains(item)) {
        return item;
      }
    }
    return null;
  }

  @override
  List<ValueStream<AnimationViewModel>> childrenOf(
          ValueStream<AnimationViewModel> treeItem) =>
      null;

  @override
  void drop(
      FlatTreeItem<ValueStream<AnimationViewModel>> target,
      DropState state,
      List<FlatTreeItem<ValueStream<AnimationViewModel>>> items) {
    FractionalIndex before, after;

    switch (state) {
      case DropState.above:
        before =
            _previousExcluding(target, items)?.data?.value?.animation?.order ??
                const FractionalIndex.min();
        after = target.data.value.animation.order;
        break;
      case DropState.below:
        before = target.data.value.animation.order;
        after = _nextExcluding(target, items)?.data?.value?.animation?.order ??
            const FractionalIndex.max();
        break;
      default:
        break;
    }
    for (final item in items) {
      before = FractionalIndex.between(before, after);
      item.data.value.animation.order = before;
    }
    animationManager.order.add(AnimationOrder.custom);
  }

  @override
  bool allowDrop(
      FlatTreeItem<ValueStream<AnimationViewModel>> item,
      DropState state,
      List<FlatTreeItem<ValueStream<AnimationViewModel>>> items) {
    // Only allow re-ordering.
    switch (state) {
      case DropState.above:
      case DropState.below:
        return true;
      default:
        return false;
    }
  }

  @override
  bool isDisabled(ValueStream<AnimationViewModel> treeItem) {
    return false;
  }

  @override
  bool isProperty(ValueStream<AnimationViewModel> treeItem) => false;

  @override
  List<FlatTreeItem<ValueStream<AnimationViewModel>>> onDragStart(
          DragStartDetails details,
          FlatTreeItem<ValueStream<AnimationViewModel>> item) =>
      [item];

  @override
  void onMouseEnter(PointerEnterEvent event,
      FlatTreeItem<ValueStream<AnimationViewModel>> item) {
    animationManager.mouseOver.add(item.data.value);
  }

  @override
  void onMouseExit(PointerExitEvent event,
      FlatTreeItem<ValueStream<AnimationViewModel>> item) {
    animationManager.mouseOut.add(item.data.value);
  }

  @override
  void onTap(FlatTreeItem<ValueStream<AnimationViewModel>> item) {
    animationManager.select.add(item.data.value);
  }

  @override
  int spacingOf(ValueStream<AnimationViewModel> treeItem) => 1;

  @override
  void onRightClick(BuildContext context, PointerDownEvent event,
      FlatTreeItem<ValueStream<AnimationViewModel>> item) {
    var viewModel = item.data.value;
    const double width = 130;
    ListPopup<PopupContextItem>.show(
      context,
      showArrow: false,
      // direction: PopupDirection.rightToBottom,
      position: event.position + const Offset(0, -6),
      width: width,
      itemBuilder: (popupContext, item, isHovered) =>
          item.itemBuilder(popupContext, isHovered),
      items: [
        PopupContextItem('Duplicate', select: () => false),
        PopupContextItem(
          'Delete',
          select: () => animationManager.delete.add(viewModel),
        ),
        PopupContextItem.separator(),
        PopupContextItem('Sort', popupWidth: width, popup: [
          PopupContextItem(
            'A-Z',
            select: () => animationManager.order.add(AnimationOrder.aToZ),
          ),
          PopupContextItem(
            'Z-A',
            select: () => animationManager.order.add(AnimationOrder.zToA),
          ),
        ]),
      ],
    );
  }
}

class AnimationHierarchyView extends StatefulWidget {
  final AnimationManager animationManager;

  const AnimationHierarchyView({
    @required this.animationManager,
    Key key,
  }) : super(key: key);

  @override
  _AnimationHierarchyViewState createState() => _AnimationHierarchyViewState();
}

class _AnimationHierarchyViewState extends State<AnimationHierarchyView> {
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
  void didUpdateWidget(AnimationHierarchyView oldWidget) {
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
                iconColor: Colors.white,
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
                                  ? Colors.white
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
