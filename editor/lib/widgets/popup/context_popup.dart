import 'package:flutter/material.dart';

import 'list_popup.dart';

class ContextItem extends PopupListItem {
  final WidgetBuilder iconBuilder;
  final String name;
  final String shortcut;
  final WidgetBuilder widgetBuilder;
  final List<ContextItem> popup;
  final VoidCallback select;
  final bool isActive;

  ContextItem(this.name,
      {this.iconBuilder,
      this.shortcut,
      this.widgetBuilder,
      this.popup,
      this.select,
      this.isActive = false});

  ContextItem.separator()
      : iconBuilder = null,
        name = null,
        shortcut = null,
        widgetBuilder = null,
        popup = null,
        select = null,
        isActive = false;

  bool get isSeparator => name == null;

  Widget itemBuilder(BuildContext context, bool isHovered) {
    if (isSeparator) {
      return Center(
          child: Container(height: 1, color: Colors.white.withOpacity(0.08)));
    }
    return Row(
      children: [
        SizedBox(width: 20),
        if (iconBuilder != null) iconBuilder.call(context),
        if (iconBuilder != null) SizedBox(width: 10),
        Text(
          name,
          style: TextStyle(
            fontFamily: 'Roboto-Regular',
            fontSize: 13,
            color: isHovered || isActive
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
        Expanded(child: Container()),
        if (shortcut != null)
          Text(
            shortcut,
            style: TextStyle(
              fontFamily: 'Roboto-Regular',
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        SizedBox(width: 20),
      ],
    );
  }

  @override
  bool get canSelect => !isSeparator;

  @override
  double get height => isSeparator ? 20 : 40;
}
