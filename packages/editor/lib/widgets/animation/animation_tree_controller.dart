import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:fractional/fractional.dart';
import 'package:rive_editor/rive/managers/animation/animations_manager.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';

import 'package:core/debounce.dart';

class AnimationTreeController
    extends TreeController<ValueStream<AnimationViewModel>> {
  final AnimationsManager animationManager;
  StreamSubscription<Iterable<ValueStream<AnimationViewModel>>> _subscription;
  Iterable<ValueStream<AnimationViewModel>> _data = [];

  AnimationTreeController(this.animationManager) : super() {
    _subscription = animationManager.animations.listen(_animationsChanged);
  }

  @override
  Iterable<ValueStream<AnimationViewModel>> get data => _data;

  void _animationsChanged(
      Iterable<ValueStream<AnimationViewModel>> animations) {
    _data = animations.toList();
    flatten();
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

    double width = RiveTheme.find(context).dimensions.contextMenuWidth;
    ListPopup<PopupContextItem>.show(
      context,
      showArrow: false,
      // direction: PopupDirection.rightToBottom,
      position: event.position + const Offset(0, -6),
      width: width,
      itemBuilder: (popupContext, item, isHovered) =>
          item.itemBuilder(popupContext, isHovered),
      items: [
        // TODO: Add duplication logic.
        // PopupContextItem('Duplicate', select: () => false),
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
