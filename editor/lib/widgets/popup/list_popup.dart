import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/nullable_listenable_builder.dart';
import 'package:rive_editor/widgets/path_widget.dart';
import 'base_popup.dart';

typedef SelectCallback<T> = void Function();

abstract class PopupListItem {
  /// Whether the item can be interacted with/selected by the user. For example,
  /// a separator cannot be clicked on.
  bool get canSelect;

  /// Height for the item in the popup list.
  double get height;

  /// Wether selection of the item will result in dismissing the .
  bool get dismissOnSelect;

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
}

typedef ListPopupItemBuilder<T> = Widget Function(
    BuildContext context, T item, bool isHovered);
typedef ListPopupItemEvent<T> = void Function(BuildContext context, T item);

final _pathArrow = Path()
  ..lineTo(6, -6)
  ..lineTo(12, 0)
  ..close();

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

  void focusRight(BuildContext context) {
    if (_focus == null) {
      return;
    }
    if (_focus.popup != null) {
      showChildPopup(context, child: _focus);
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
        alignment: Alignment.topRight,
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
    Offset offset = const Offset(0, 10),
    bool showArrow = true,
    Alignment alignment = Alignment.bottomLeft,
    List<T> items = const [],
    Color background = const Color.fromRGBO(17, 17, 17, 1),
    ListPopup<T> parent,
    bool handleKeyPresses = true,
  }) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final boxOffset = renderBox.localToGlobal(Offset.zero);

    var media = MediaQuery.of(context);
    var position = boxOffset + alignment.alongSize(size);

    var top = position.dy + offset.dy;
    var left = position.dx + offset.dx;

    // bool useList = media.size.height > height;
    var list = ListPopup<T>(
      items,
      itemBuilder: itemBuilder,
      parent: parent,
      handleKeyPresses: handleKeyPresses,
    );

    var listFocusNode = FocusNode(canRequestFocus: true, skipTraversal: true);
    list._popup = Popup.show(
      context,
      onClose: list.close,
      builder: (context) {
        return Positioned(
          left: left,
          top: top,
          width: width,
          child: RawKeyboardListener(
            focusNode: listFocusNode,
            onKey: (event) {
              return;
              if (event is RawKeyDownEvent) {
                // Ugh can't switch on these :(
                if (event.physicalKey == PhysicalKeyboardKey.arrowUp) {
                  list.focusUp();
                } else if (event.physicalKey == PhysicalKeyboardKey.arrowDown) {
                  list.focusDown();
                } else if (event.physicalKey == PhysicalKeyboardKey.arrowLeft) {
                  list.focusLeft();
                }
              }

              // TODO: figure out why we can't keep focus without this. If we
              // comment this out, we'll lose focus after first press. Needs to
              // be debounced as it seems like something else is attempting to
              // grab focus.
              Timer(const Duration(milliseconds: 1),
                  () => listFocusNode.requestFocus());
            },
            child: MouseRegion(
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    showArrow
                        ? PathWidget(
                            path: _pathArrow,
                            nudge: const Offset(10, 0),
                            paint: Paint()
                              ..color = background
                              ..style = PaintingStyle.fill
                              ..isAntiAlias = true,
                          )
                        : null,
                    ValueListenableBuilder<List<T>>(
                      valueListenable: list.values,
                      builder: (context, values, _) {
                        var height = min(
                            media.size.height - top,
                            values.fold<double>(
                                    0.0, (v, item) => v + item.height) +
                                margin * 2);
                        return values.isEmpty
                            ? Container()
                            : Container(
                                decoration: BoxDecoration(
                                  color: background,
                                  borderRadius: BorderRadius.circular(5.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3473),
                                      offset: const Offset(0.0, 30.0),
                                      blurRadius: 30,
                                    )
                                  ],
                                ),
                                height: height,
                                child: Scrollbar(
                                  child: ListView.builder(
                                    physics: const ClampingScrollPhysics(),
                                    padding: EdgeInsets.only(
                                        top: margin, bottom: margin),
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
                  ].where((item) => item != null).toList(growable: false),
                ),
              ),
            ),
          ),
        );
      },
    );

    listFocusNode.requestFocus();

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (!widget.item.canSelect) {
          return;
        }
        widget.item.select?.call();
        if (widget.item.dismissOnSelect) {
          Popup.closeAll();
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
            // We want this item to handle keypresses if it's focused or if our
            // list has no focus and this happens to be the first item in it. We
            // also want to make sure we don't hanlde focus if the popup opener
            // explicitly asked us not to. Usually this means they'll handle key
            // presses themselves or/and they rely on focus for context (like a
            // type-ahead combobox).
            var hasKeyboardFocus = widget.listPopup.handleKeyPresses &&
                (isFocused ||
                    (widget.listPopup.focus == null &&
                        widget.listPopup.values.value.first == widget.item));

            return Container(
              color: isFocused ? const Color.fromRGBO(26, 26, 26, 1) : null,
              child: _keyboardListener(
                hasKeyboardFocus,
                context: context,
                child: NullableListenableBuilder(
                  listenable: widget.item.rebuildItem,
                  builder: (context, ChangeNotifier value, _) =>
                      widget.itemBuilder(context, widget.item, isFocused),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Luigi: We register a keyboard listener on the focused item. I'd previously
  // implemented this as a listener for the whole list, but in some cases we
  // need the build context of the item that's focused, so this allows us to get
  // that without needing to pass contexts around with item data.
  Widget _keyboardListener(bool isFocused,
      {Widget child, BuildContext context}) {
    if (isFocused) {
      var focus = FocusNode();
      focus.requestFocus();
      return RawKeyboardListener(
        focusNode: focus,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            // Ugh can't switch on these :(
            if (event.physicalKey == PhysicalKeyboardKey.escape) {
              widget.listPopup.close();
            } else if (event.physicalKey == PhysicalKeyboardKey.enter ||
                event.physicalKey == PhysicalKeyboardKey.numpadEnter) {
              if (!widget.item.canSelect) {
                return;
              }
              widget.item.select?.call();
              Popup.closeAll();
            } else if (event.physicalKey == PhysicalKeyboardKey.arrowUp) {
              widget.listPopup.focusUp();
            } else if (event.physicalKey == PhysicalKeyboardKey.arrowDown) {
              widget.listPopup.focusDown();
            } else if (event.physicalKey == PhysicalKeyboardKey.arrowLeft) {
              widget.listPopup.focusLeft();
            } else if (event.physicalKey == PhysicalKeyboardKey.arrowRight) {
              // Focus right needs context as it can open a new popup.
              widget.listPopup.focusRight(context);
            } else {
              // TODO: Leaving this commented in as a reminder that we need to
              // do something about preventing default Flutter widgets from
              // grabbing focus. The DropDownButton ViewScaleDropdown was
              // stealing focus after every key press. I fixed this by giving it
              // a skipTraversal: true in a custom FocusNode passed to it. See
              // scale_dropdown.dart Timer(const Duration(milliseconds: 1), ()
              // => focus.requestFocus());
            }
          }
        },
        child: child,
      );
    }
    return child;
  }
}
