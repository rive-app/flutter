import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/path_widget.dart';
import 'base_popup.dart';

typedef SelectCallback<T> = void Function(T param);

abstract class PopupListItem<T> {
  bool get canSelect;
  double get height;
  List<PopupListItem<T>> get popup;
  SelectCallback<T> get select;
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
class ListPopup<A, T extends PopupListItem<A>> {
  OverlayEntry _overlayEntry;
  ListPopup();
  ListPopup<A, T> _subPopup;
  __PopupListItemShellState<A, T> _subPopupRow;

  bool get isOpen => Popup.isOpen(_overlayEntry);

  void rowEntered(__PopupListItemShellState<A, T> row) {
    if (_subPopupRow == row || _subPopup == null) {
      return;
    }
    closeSubPopup();
  }

  void closeSubPopup() {
    if (_subPopup == null) {
      return;
    }
    _subPopup.closeSubPopup();
    Popup.remove(_subPopup._overlayEntry);
    _subPopupRow.hover = false;
    _subPopupRow = null;
    _subPopup = null;
  }

  bool showChildPopup(
    BuildContext context, {
    @required ListPopupItemBuilder<T> itemBuilder,
    __PopupListItemShellState<A, T> parentState,
    A selectArg,
    double width = 177,
    double margin = 10,
    // double arrow = 10,
    List<T> items = const [],
    Color background = const Color.fromRGBO(17, 17, 17, 1),
  }) {
    if (_subPopupRow == parentState) {
      return false;
    }
    _subPopup = ListPopup.show(
      context,
      itemBuilder: itemBuilder,
      isChild: true,
      selectArg: selectArg,
      width: width,
      margin: margin,
      // double arrow = 10,
      items: items,
      background: background,
    );
    _subPopupRow = parentState;
    return true;
  }

  factory ListPopup.show(
    BuildContext context, {
    @required ListPopupItemBuilder<T> itemBuilder,
    bool isChild = false,
    A selectArg,
    double width = 177,
    double margin = 10,
    // double arrow = 10,
    List<T> items = const [],
    Color background = const Color.fromRGBO(17, 17, 17, 1),
  }) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    var media = MediaQuery.of(context);
    var top = !isChild ? offset.dy + size.height + margin : offset.dy - margin;
    var left = isChild ? offset.dx + size.width : offset.dx;

    var height = min(media.size.height - top,
        items.fold<double>(0.0, (v, item) => v + item.height) + margin * 2);

    // bool useList = media.size.height > height;
    var list = ListPopup<A, T>();

    list._overlayEntry = Popup.show(
      context,
      builder: (context) {
        return Positioned(
          left: left,
          top: top,
          width: width,
          child: MouseRegion(
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  !isChild
                      ? PathWidget(
                          path: _pathArrow,
                          nudge: const Offset(10, 0),
                          paint: Paint()
                            ..color = background
                            ..style = PaintingStyle.fill
                            ..isAntiAlias = true,
                        )
                      : null,
                  Container(
                    height: height,
                    child: Scrollbar(
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(top: margin, bottom: margin),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          var item = items[index];
                          return Container(
                            height: item.height,
                            child: _PopupListItemShell<A, T>(
                              list,
                              itemBuilder: itemBuilder,
                              item: item,
                              selectArg: selectArg,
                            ),
                          );
                        },
                      ),
                    ),
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
                  ),
                ].where((item) => item != null).toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
    return list;
  }
}

class _PopupListItemShell<A, T extends PopupListItem<A>>
    extends StatefulWidget {
  final ListPopup<A, T> listPopup;
  final ListPopupItemBuilder<T> itemBuilder;
  final T item;
  final A selectArg;

  const _PopupListItemShell(
    this.listPopup, {
    Key key,
    this.itemBuilder,
    this.item,
    this.selectArg,
  }) : super(key: key);

  @override
  __PopupListItemShellState<A, T> createState() =>
      __PopupListItemShellState<A, T>();
}

class __PopupListItemShellState<A, T extends PopupListItem<A>>
    extends State<_PopupListItemShell<A, T>> {
  bool _isHovered = false;

  bool get hover => _isHovered;

  set hover(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() {
      _isHovered = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (!widget.item.canSelect) {
          return;
        }
        widget.item.select?.call(widget.selectArg);
        Popup.closeAll();
      },
      child: MouseRegion(
        onEnter: (details) {
          widget.listPopup.rowEntered(this);
          if (!widget.item.canSelect) {
            return;
          }

          // Hic Sunt Dracones: Please don't touch this.
          if (_isHovered || !widget.listPopup.isOpen) {
            return;
          }
          hover = true;
          if (widget.item.popup != null) {
            widget.listPopup.showChildPopup(
              context,
              parentState: this,
              selectArg: widget.selectArg,
              items: widget.item.popup.cast<T>(),
              itemBuilder: widget.itemBuilder,
            );
          }
        },
        onExit: (details) {
          if (widget.listPopup._subPopupRow == this) {
            return;
          }
          hover = false;
        },
        child: Container(
          color: _isHovered ? const Color.fromRGBO(26, 26, 26, 1) : null,
          child: widget.itemBuilder(context, widget.item, _isHovered),
        ),
      ),
    );
  }
}
