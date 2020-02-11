import 'package:flutter/material.dart';

import 'list_popup.dart';

typedef ItemCounter = int Function();

class PopupButton<A, T extends PopupListItem<A>> extends StatelessWidget {
  final WidgetBuilder builder;
  final List<T> items;
  final ListPopupItemBuilder<T> itemBuilder;
  final ListPopupItemEvent<T> itemSelected;
  final A selectArg;

  /// TODO: figure out if we want to break this into sets of more generic
  /// widgets or somehow manage the styling across different popup buttons.
  final double backgroundOpacity;

  const PopupButton(
      {Key key,
      this.builder,
      this.items,
      this.itemBuilder,
      this.itemSelected,
      this.selectArg,
      this.backgroundOpacity = 1.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        ListPopup<A, T>.show(
          context,
          selectArg: selectArg,
          items: items,
          itemBuilder: itemBuilder,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(68, 68, 68, backgroundOpacity),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: builder(context),
      ),
    );
  }
}
