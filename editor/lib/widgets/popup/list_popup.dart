import 'dart:math';

import 'package:flutter/material.dart';
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
  OverlayEntry _overlayEntry;
  ListPopup();
  ListPopup<T> _subPopup;
  __PopupListItemShellState<T> _subPopupRow;

  bool get isOpen => Popup.isOpen(_overlayEntry);

  void rowEntered(__PopupListItemShellState<T> row) {
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

  bool close() => Popup.remove(_overlayEntry);

  bool showChildPopup(
    BuildContext context, {
    @required ListPopupItemBuilder<T> itemBuilder,
    __PopupListItemShellState<T> parentState,
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
    var list = ListPopup<T>();

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
                            child: _PopupListItemShell<T>(
                              list,
                              itemBuilder: itemBuilder,
                              item: item,
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
  __PopupListItemShellState<T> createState() => __PopupListItemShellState<T>();
}

class __PopupListItemShellState<T extends PopupListItem>
    extends State<_PopupListItemShell<T>> {
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
        widget.item.select?.call();
        if (widget.item.dismissOnSelect) {
          Popup.closeAll();
        }
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

        // We had replaced the container with a Stack to fix the rebuilding of the sub-widget tree returned by the itemBuilder. This is due to Container being stateless, hence everything underneath it rebuilds when any property of the container changes.
        // child: Stack(children: [
        //   Positioned.fill(
        //     child: Container(
        //       color: _isHovered ? const Color.fromRGBO(26, 26, 26, 1) : null,
        //     ),
        //   ),
        //   Positioned.fill(
        //     child: widget.itemBuilder(context, widget.item, _isHovered),
        //   )
        // ]
        child: Container(
          color: _isHovered ? const Color.fromRGBO(26, 26, 26, 1) : null,
          child: NullableListenableBuilder(
            listenable: widget.item.rebuildItem,
            builder: (context, ChangeNotifier value, _) =>
                widget.itemBuilder(context, widget.item, _isHovered),
          ),
        ),

        // color: _isHovered ? const Color.fromRGBO(26, 26, 26, 1) : null,
        // child:  TintedIcon(color:Colors.red, icon:'tool-auto')//widget.itemBuilder(context, widget.item, _isHovered),
      ),
    );
  }
}
