import 'package:flutter/material.dart';

import 'list_popup.dart';

/// Callback providing the opened popup.
typedef PopupOpened<T extends PopupListItem> = void Function(ListPopup<T>);

/// A widget that opens a popup when it is tapped on.
class PopupButton<T extends PopupListItem> extends StatelessWidget {
  final WidgetBuilder builder;
  final List<T> items;
  final ListPopupItemBuilder<T> itemBuilder;
  final PopupOpened<T> opened;
  final double width;

  const PopupButton({
    Key key,
    this.builder,
    this.items,
    this.itemBuilder,
    this.opened,
    this.width = 177,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        var popup = ListPopup<T>.show(
          context,
          items: items,
          itemBuilder: itemBuilder,
          width: width,
        );
        opened?.call(popup);
      },
      child: builder(context),
    );
  }
}
