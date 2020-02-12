import 'package:flutter/material.dart';

import 'list_popup.dart';

/// Callback providing the opened popup.
typedef PopupOpened<A, T extends PopupListItem<A>> = void Function(
    ListPopup<A, T>);

/// A widget that opens a popup when it is tapped on.
class PopupButton<A, T extends PopupListItem<A>> extends StatelessWidget {
  final WidgetBuilder builder;
  final List<T> items;
  final ListPopupItemBuilder<T> itemBuilder;
  final A selectArg;
  final PopupOpened<A, T> opened;

  const PopupButton({
    Key key,
    this.builder,
    this.items,
    this.itemBuilder,
    this.selectArg,
    this.opened,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        var popup = ListPopup<A, T>.show(
          context,
          selectArg: selectArg,
          items: items,
          itemBuilder: itemBuilder,
        );
        opened?.call(popup);
      },
      child: builder(context),
    );
  }
}
