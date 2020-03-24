import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/nullable_listenable_builder.dart';
import 'package:rive_editor/widgets/popup/arrow_popup.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'base_popup.dart';

typedef SelectCallback<T> = void Function();

abstract class PopupListItem {
  /// Whether the item can be interacted with/selected by the user. For example,
  /// a separator cannot be clicked on.
  bool get canSelect;

  /// Height for the item in the popup list.
  double get height;

  /// Whether selection of the item will result in dismissing the popup.
  bool get dismissOnSelect => true;

  /// Whether all items get dismissed when this one does.
  bool get dismissAll => true;

  /// Child popup displayed when this list item is hovered over.
  List<PopupListItem> get popup;

  /// Callback to invoke when the item is pressed on/selected.
  SelectCallback get select;

  /// Optional change notifier that can be used to signal the item needs to be
  /// rebuilt in response to some external event.
  ChangeNotifier get rebuildItem;

  /// Used to track which item is currently in focus (hovered or selected via
  /// arrow keys).
  final ValueNotifier<bool> _isFocused = ValueNotifier(false);

  // Check if this item is currently focused (hovered or highlighted via arrow
  // key selection).
  bool get isFocused => _isFocused.value;

  /// Overridable child widget.
  Widget get child => null;

  /// The context of the shell widget item.
  BuildContext shellContext;
}

typedef ListPopupItemBuilder<T> = Widget Function(
    BuildContext context, T item, bool isHovered);
typedef ListPopupItemEvent<T> = void Function(BuildContext context, T item);

/// Displays list of items in a popup, internally stores which item is currently
/// opened with a sub-popup so that sub-popups can be closed if the top level
/// one is closed.
///
/// Consider re-architecting this in the future as there is quite a bit of
/// complexity with the management of the sub-popups.
class ListPopup<T extends PopupListItem> {
  Popup _popup;
  final ListPopup<T> parent;
  final ListPopupItemBuilder<T> itemBuilder;
  final bool handleKeyPresses;
  ListPopup(List<T> listValues,
      {this.itemBuilder, this.parent, this.handleKeyPresses})
      : _values = ValueNotifier<List<T>>(listValues);
  ListPopup<T> _subPopup;
  T _child;

  final ValueNotifier<List<T>> _values;
  ValueNotifier<List<T>> get values => _values;

  T _focus;

  /// Get the currently focused item in this popup. Focus represents either
  /// hover or keyboard (via arrow keys) focus. This is useful for items in
  /// comboboxes when using type-ahead but also in general to use the keyboard
  /// to navigate popups. Since all our popups share this basecode, we
  /// automatically get keyboard navigation on all lists that follow this model
  /// and use the [ListPopup].
  T get focus => _focus;
  set focus(T value) {
    if (_focus == value) {
      return;
    }
    if (_focus != null) {
      _focus._isFocused.value = false;
    }
    _focus = value;
    if (_focus != null) {
      _focus._isFocused.value = true;
    }
  }

  /// Whether this popup is open and visible.
  bool get isOpen => Popup.isOpen(_popup);

  /// Called to let the list know one of the widgets representing an item was
  /// hovered.
  void rowEntered(T row) {
    if (_child == row || _subPopup == null) {
      return;
    }
    closeSubPopup();
  }

  /// Close a sub-popup owned by this popup list.
  void closeSubPopup() {
    if (_subPopup == null) {
      return;
    }
    _subPopup.closeSubPopup();
    Popup.remove(_subPopup._popup);
    // _parent.focus = null;
    _child = null;
    _subPopup = null;
  }

  /// Close this popup.
  bool close() {
    parent?._child = null;
    focus = null;
    return Popup.remove(_popup);
  }

  /// Move the focus down, cycle back to the top if we hit the bottom.
  void focusDown() {
    var list = _values.value;
    if (list.isEmpty) {
      return;
    }
    if (_focus == null) {
      focus = list.first;
    } else {
      for (int i = 0; i < list.length; i++) {
        var possibleFocus = list[(list.indexOf(_focus) + 1 + i) % list.length];
        if (possibleFocus.canSelect) {
          focus = possibleFocus;
          break;
        }
      }
    }
  }

  /// Move the focus up, cycle back to the bottom if we hit the top.
  void focusUp() {
    var list = _values.value;
    if (list.isEmpty) {
      return;
    }
    if (_focus == null) {
      focus = list.last;
    } else {
      for (int i = 0; i < list.length; i++) {
        var possibleFocus =
            list[(list.indexOf(_focus) - (1 + i) + list.length) % list.length];
        if (possibleFocus.canSelect) {
          focus = possibleFocus;
          break;
        }
      }
    }
  }

  /// Move the selected item list to the left, right now this just means close
  /// the current sub-popup.
  void focusLeft() {
    // close if we're a subpopup
    if (parent != null) {
      close();
    }
  }

  void focusRight() {
    if (_focus == null) {
      return;
    }
    if (_focus.popup != null) {
      showChildPopup(_focus.shellContext, child: _focus);
      // Grab first focus.
      _subPopup.focusDown();
    }
  }

  bool showChildPopup(
    BuildContext context, {
    double width = 177,
    double margin = 10,
    // double arrow = 10,
    T child,
    Color background = const Color.fromRGBO(17, 17, 17, 1),
  }) {
    if (_child == child) {
      return false;
    }
    _subPopup = ListPopup.show(context,
        itemBuilder: itemBuilder,
        showArrow: false,
        width: width,
        margin: margin,
        direction: PopupDirection.rightToBottom,
        directionPadding: 0,
        offset: Offset(0, -margin),
        // double arrow = 10,
        items: child.popup.cast<T>(),
        background: background,
        parent: this);
    _child = child;

    return true;
  }

  factory ListPopup.show(
    BuildContext context, {
    @required ListPopupItemBuilder<T> itemBuilder,
    double width = 177,
    double margin = 10,
    Offset offset = Offset.zero,
    double directionPadding = 16,
    // Flag to display the small arrow at the top of the popup
    bool showArrow = true,
    Offset arrowTweak = Offset.zero,
    PopupDirection direction = PopupDirection.bottomToRight,
    List<T> items = const [],
    Color background = const Color.fromRGBO(17, 17, 17, 1),
    ListPopup<T> parent,
    bool handleKeyPresses = true,
    bool includeCloseGuard = false,
    VoidCallback onClose,
  }) {
    ListPopup<T> list;

    var focusNode = FocusNode(
      canRequestFocus: true,
      debugLabel: 'List Popup Focus',
      skipTraversal: true,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.physicalKey == PhysicalKeyboardKey.escape) {
            list.close();
          } else if (event.physicalKey == PhysicalKeyboardKey.enter ||
              event.physicalKey == PhysicalKeyboardKey.numpadEnter) {
            if (list.focus == null || !list.focus.canSelect) {
              return true;
            }
            list.focus.select?.call();
            if (list.focus.dismissAll) {
              Popup.closeAll();
            } else {
              list.close();
            }
            return true;
          } else if (event.physicalKey == PhysicalKeyboardKey.arrowUp) {
            list.focusUp();
            return true;
          } else if (event.physicalKey == PhysicalKeyboardKey.arrowDown) {
            list.focusDown();
            return true;
          } else if (event.physicalKey == PhysicalKeyboardKey.arrowLeft) {
            list.focusLeft();
            return true;
          } else if (event.physicalKey == PhysicalKeyboardKey.arrowRight) {
            // Focus right needs context as it can open a new popup.
            list.focusRight();
            return true;
          }
        }
        return false;
      },
    );

    // Request focus as soon as we attach.
    focusNode.requestFocus();

    list = ListPopup<T>(
      items,
      itemBuilder: itemBuilder,
      parent: parent,
      handleKeyPresses: handleKeyPresses,
    );

    list._popup = ArrowPopup.show(
      context,
      width: width,
      offset: offset,
      directionPadding: directionPadding,
      direction: direction,
      showArrow: showArrow,
      arrowTweak: arrowTweak,
      background: background,
      onClose: onClose == null
          ? list.close
          : () {
              onClose();
              list.close();
            },
      includeCloseGuard: includeCloseGuard,
      builder: (context) {
        return Focus(
          focusNode: focusNode,
          child: ValueListenableBuilder<List<T>>(
            valueListenable: list.values,
            builder: (context, values, _) {
              // The desired full height, the ListPopupLayoutDelegate
              // won't let us exceed our constraints if these are too
              // tall.
              var height =
                  values.fold<double>(0, (v, item) => v + item.height) +
                      margin * 2;
              return values.isEmpty
                  ? const SizedBox()
                  : SizedBox(
                      height: height,
                      child: Scrollbar(
                        child: ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(top: margin, bottom: margin),
                          itemCount: values.length,
                          itemBuilder: (context, index) {
                            var item = values[index];
                            return Container(
                              height: item.height,
                              child: _PopupListItemShell<T>(
                                list,
                                itemBuilder: itemBuilder,
                                item: item,
                              ),
                            );
                          },
                        ),
                      ),
                    );
            },
          ),
        );
      },
    );

    return list;
  }
}

class _PopupListItemShell<T extends PopupListItem> extends StatefulWidget {
  final ListPopup<T> listPopup;
  final ListPopupItemBuilder<T> itemBuilder;
  final T item;

  const _PopupListItemShell(
    this.listPopup, {
    Key key,
    this.itemBuilder,
    this.item,
  }) : super(key: key);

  @override
  __PopupListItemShellState createState() => __PopupListItemShellState<T>();
}

class __PopupListItemShellState<T extends PopupListItem>
    extends State<_PopupListItemShell<T>> {
  @override
  void initState() {
    widget.item.shellContext = context;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (!widget.item.canSelect) {
          return;
        }
        widget.item.select?.call();
        if (widget.item.dismissOnSelect) {
          if (widget.item.dismissAll) {
            Popup.closeAll();
          } else {
            widget.listPopup.close();
          }
        }
      },
      child: MouseRegion(
        onEnter: (details) {
          widget.listPopup.rowEntered(widget.item);
          if (!widget.item.canSelect) {
            return;
          }

          // Hic Sunt Dracones: Please don't touch this.
          if (widget.item.isFocused || !widget.listPopup.isOpen) {
            return;
          }
          // Let the list know that we want focus.
          widget.listPopup.focus = widget.item;

          // Since we're hovering, auto open any sub-list.
          if (widget.item.popup != null) {
            widget.listPopup.showChildPopup(
              context,
              child: widget.item,
            );
          }
        },
        onExit: (details) {
          if (widget.listPopup._child == widget.item) {
            return;
          }

          // Only remove focus on mouse exit if we were the previous focus.
          if (widget.listPopup.focus == widget.item) {
            widget.listPopup.focus = null;
          }
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.item._isFocused,
          builder: (context, isFocused, _) {
            return Container(
              color: isFocused ? const Color.fromRGBO(26, 26, 26, 1) : null,
              child: NullableListenableBuilder(
                listenable: widget.item.rebuildItem,
                builder: (context, ChangeNotifier value, _) =>
                    widget.itemBuilder(context, widget.item, isFocused),
              ),
            );
          },
        ),
      ),
    );
  }
}
