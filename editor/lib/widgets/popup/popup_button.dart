import 'package:flutter/material.dart';

import 'list_popup.dart';

typedef ItemCounter = int Function();

class PopupButton<T extends PopupListItem> extends StatelessWidget {
  final WidgetBuilder builder;
  final List<T> items;
  final ListPopupItemBuilder itemBuilder;
  final ListPopupItemEvent itemSelected;

  const PopupButton({
    Key key,
    this.builder,
    this.items,
    this.itemBuilder,
    this.itemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        ListPopup.show(
          context,
          items: items,
          itemBuilder: itemBuilder,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(68, 68, 68, 1),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: builder(context),
      ),
    );
  }
}
