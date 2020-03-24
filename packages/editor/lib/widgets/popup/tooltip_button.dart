import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/popup/popup_tooltip.dart';
import 'package:rive_editor/widgets/popup/tooltip_item.dart';


/// A widget that opens a tooltip when it is hovered.
class TooltipButton extends StatelessWidget {
  final WidgetBuilder builder;
  final List<TooltipItem> items;
  final TooltipItemBuilder itemBuilder;
  final double width;

  TooltipPopup _popup;

  TooltipButton({
    @required this.builder,
    @required this.items,
    Key key,
    this.itemBuilder,
    this.width = 177,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _popup = TooltipPopup.show(
          context,
          items: items,
          itemBuilder: itemBuilder,
          width: width,
        );
      },
      onExit: (_) => _popup?.close(),
      child: builder(context),
    );
  }
}
