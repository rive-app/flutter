import 'dart:math';

import 'package:flutter/material.dart';
import '../path_widget.dart';
import 'popup.dart';

typedef SelectCallback<T> = void Function(T param);

abstract class PopupListItem<T> {
  bool get canSelect;
  double get height;
  SelectCallback<T> get select;
}

typedef ListPopupItemBuilder<T> = Widget Function(
    BuildContext context, T item, bool isHovered);
typedef ListPopupItemEvent<T> = void Function(BuildContext context, T item);

final _pathArrow = Path()
  ..lineTo(6, -6)
  ..lineTo(12, 0)
  ..close();

class ListPopup {
  static void show<A, T extends PopupListItem<A>>(
    BuildContext context, {
    @required ListPopupItemBuilder<T> itemBuilder,
    A selectArg,
    double width = 177,
    double margin = 10,
    double arrow = 10,
    List<T> items = const [],
    Color background = const Color.fromRGBO(17, 17, 17, 1),
  }) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    var media = MediaQuery.of(context);
    var top = offset.dy + size.height + margin;

    var height = min(media.size.height - top,
        items.fold<double>(0.0, (v, item) => v + item.height) + margin * 2);

    // bool useList = media.size.height > height;
    Popup.show(
      context,
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: top,
          width: width,
          child: MouseRegion(
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PathWidget(
                    path: _pathArrow,
                    nudge: const Offset(10.0, 0),
                    paint: Paint()
                      ..color = background
                      ..style = PaintingStyle.fill
                      ..isAntiAlias = true,
                  ),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PopupListItemShell<A, T extends PopupListItem<A>>
    extends StatefulWidget {
  final ListPopupItemBuilder<T> itemBuilder;
  final T item;
  final A selectArg;

  const _PopupListItemShell({
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
    extends State<_PopupListItemShell> {
  _PopupListItemShell<A, T> get selectWidget =>
      widget as _PopupListItemShell<A, T>;
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (!widget.item.canSelect) {
          return;
        }
        selectWidget.item.select?.call(selectWidget.selectArg);
        Popup.closeAll();
      },
      child: MouseRegion(
        onEnter: (details) {
          if (!widget.item.canSelect) {
            return;
          }
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (details) {
          setState(() {
            _isHovered = false;
          });
        },
        child: Container(
          color: _isHovered ? const Color.fromRGBO(26, 26, 26, 1) : null,
          child: widget.itemBuilder(context, widget.item, _isHovered),
        ),
      ),
    );
  }
}
