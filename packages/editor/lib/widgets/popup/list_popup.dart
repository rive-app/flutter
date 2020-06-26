import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_widgets/nullable_listenable_builder.dart';
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

  /// Width of the child popup window
  double get popupWidth => 177;

  /// Callback to invoke when the item is pressed on/selected.
  SelectCallback get select;

  /// Optional change notifier that can be used to signal the item needs to be
  /// rebuilt in response to some external event.
  Listenable get rebuildItem;

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
  ArrowPopup _arrow;
  ArrowPopup get arrowPopup => _arrow;
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
  bool get isOpen => Popup.isOpen(_arrow.popup);

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
    Popup.remove(_subPopup._arrow.popup);
    // _parent.focus = null;
    _child = null;
    _subPopup = null;
  }

  /// Close this popup.
  bool close() {
    parent?._child = null;
    focus = null;
    return Popup.remove(_arrow.popup);
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
      showChildPopup(
        _focus.shellContext,
        width: _focus.popupWidth ?? 177,
        child: _focus,
      );
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
    _subPopup = ListPopup.show(
      context,
      itemBuilder: itemBuilder,
      showArrow: false,
      width: width,
      margin: margin,
      direction: PopupDirection.rightToBottom,

      // Intentionally set fallback to null, which tells it to attempt shifting
      // vertical before popping horizontal (as you'd expect a subpopup to
      // attempt fitting).
      fallbackDirections: null,

      directionPadding: 0,
      offset: Offset(0, -margin),
      // double arrow = 10,
      items: child.popup.cast<T>(),
      background: background,
      parent: this,
    );
    _child = child;

    return true;
  }

  factory ListPopup.show(
    BuildContext context, {
    @required ListPopupItemBuilder<T> itemBuilder,
    Offset position,
    double width = 177,
    double margin = 10,
    Offset offset = Offset.zero,
    double directionPadding = 16,
    // Flag to display the small arrow at the top of the popup
    bool showArrow = true,
    Offset arrowTweak = Offset.zero,
    PopupDirection direction = PopupDirection.bottomToRight,
    List<PopupDirection> fallbackDirections = PopupDirection.all,
    List<T> items = const [],
    Color background = const Color.fromRGBO(17, 17, 17, 1),
    ListPopup<T> parent,
    bool handleKeyPresses = true,
    bool includeCloseGuard = false,
    VoidCallback onClose,
  }) {
    ListPopup<T> list;

    bool handler(ShortcutAction action) {
      switch (action) {
        case ShortcutAction.cancel:
          list.close();
          return true;
        case ShortcutAction.confirm:
          if (list.focus == null || !list.focus.canSelect) {
            return true;
          }
          list.focus.select?.call();

          // Early out if this popup item doesn't want any dismissals on
          // select.
          if (!list.focus.dismissOnSelect) {
            return true;
          }

          if (list.focus.dismissAll) {
            Popup.closeAll();
          } else {
            list.close();
          }
          return true;
        case ShortcutAction.up:
          list.focusUp();
          return true;
        case ShortcutAction.down:
          list.focusDown();
          return true;
        case ShortcutAction.left:
          list.focusLeft();
          return true;
        case ShortcutAction.right:
          list.focusRight();
          return true;
        default:
          return false;
      }
    }

    var file = ActiveFile.find(context);
    file?.addActionHandler(handler);

    list = ListPopup<T>(
      items,
      itemBuilder: itemBuilder,
      parent: parent,
      handleKeyPresses: handleKeyPresses,
    );

    list._arrow = ArrowPopup.show(
      context,
      position: position,
      width: width,
      offset: offset,
      directionPadding: directionPadding,
      direction: direction,
      fallbackDirections: fallbackDirections,
      showArrow: showArrow,
      arrowTweak: arrowTweak,
      background: background,
      onClose: () {
        onClose?.call();
        list.close();
        file?.removeActionHandler(handler);
      },
      includeCloseGuard: includeCloseGuard,
      builder: (context) {
        return ValueListenableBuilder<List<T>>(
          valueListenable: list.values,
          builder: (context, values, _) {
            // The desired full height, the ListPopupLayoutDelegate
            // won't let us exceed our constraints if these are too
            // tall.
            var height = values.fold<double>(0, (v, item) => v + item.height) +
                margin * 2;

            return values.isEmpty
                ? const SizedBox()

                /// Need a separate focus scope here so that we don't try
                /// tabbing out of this list (weird that FocusTraversalScope
                /// didn't do this for us). Removing this will cause an error
                /// to throw when trying to tab from a TextField in this list.
                : FocusScope(
                    child: SizedBox(
                      height: height,
                      child:

                          // null width == compute the width of the content
                          //
                          // If we've specified a null width, we cannot use
                          // a scrollview (it'd have to layout all the
                          // children, even virtualized ones and Flutter's
                          // scrollviews don't really support the concept of
                          // intrinsic width). So instead we use something
                          // that does support that: a column. Just make
                          // sure you're not feeding this list too much
                          // content if you're using an intrinsic width.
                          width == null
                              ? IntrinsicWidth(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: margin),
                                      for (final item in values)
                                        Container(
                                          height: item.height,
                                          child: _PopupListItemShell<T>(
                                            list,
                                            itemBuilder: itemBuilder,
                                            item: item,
                                          ),
                                        ),
                                      SizedBox(height: margin),
                                    ],
                                  ),
                                )
                              : Scrollbar(
                                  child: ListView.builder(
                                    physics: const ClampingScrollPhysics(),
                                    padding: EdgeInsets.only(
                                        top: margin, bottom: margin),
                                    itemCount: values.length,
                                    itemBuilder: (context, index) {
                                      var item = values[index];
                                      return SizedBox(
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
                    ),
                  );
          },
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
    return PropagatingListener(
      onPointerDown: (details) {
        if (!widget.item.canSelect) {
          return;
        }

        details.stopPropagation();

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
              width: widget.item.popupWidth ?? 177,
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
                builder: (context, Listenable value, _) =>
                    widget.itemBuilder(context, widget.item, isFocused),
              ),
            );
          },
        ),
      ),
    );
  }
}
