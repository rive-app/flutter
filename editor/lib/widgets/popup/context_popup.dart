import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

import 'list_popup.dart';

class PopupContextItem<T> extends PopupListItem<T> {
  final WidgetBuilder iconBuilder;
  final String iconFilename;
  final Color iconColor;
  final String name;
  final String shortcut;
  final WidgetBuilder widgetBuilder;

  @override
  final List<PopupContextItem<T>> popup;

  @override
  final SelectCallback<T> select;

  PopupContextItem(
    this.name, {
    this.iconFilename,
    this.iconColor,
    this.iconBuilder,
    this.shortcut,
    this.widgetBuilder,
    this.popup,
    this.select,
  });

  @override
  String toString() {
    return name ?? super.toString();
  }

  PopupContextItem.separator()
      : iconBuilder = null,
        iconFilename = null,
        iconColor = null,
        name = null,
        shortcut = null,
        widgetBuilder = null,
        popup = null,
        select = null;

  bool get isSeparator => name == null;

  Widget itemBuilder(BuildContext context, bool isHovered) {
    if (isSeparator) {
      return Center(
        child: Container(
          height: 1,
          color: Colors.white.withOpacity(0.08),
        ),
      );
    }
    return Row(
      children: [
        const SizedBox(width: 20),
        if (iconBuilder != null) iconBuilder.call(context),
        if (iconBuilder != null) const SizedBox(width: 10),
        if (iconFilename != null)
          TintedIcon(
            color: iconColor ??
                (isHovered
                    ? Colors.white
                    : const Color.fromRGBO(
                        112,
                        112,
                        112,
                        1,
                      )),
            icon: iconFilename,
          ),
        if (iconFilename != null) const SizedBox(width: 10),
        Text(
          name,
          style: TextStyle(
            fontFamily: 'Roboto-Regular',
            fontSize: 13,
            color: isHovered ? Colors.white : Colors.white.withOpacity(0.5),
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
        if (popup != null && popup.isNotEmpty)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              isHovered ? Colors.white : const Color.fromRGBO(112, 112, 112, 1),
              BlendMode.srcIn,
            ),
            child: const Image(
              image: AssetImage('assets/images/icons/tool-chevron.png'),
            ),
          ),
        const SizedBox(width: 20),
      ],
    );
  }

  @override
  bool get canSelect => !isSeparator;

  @override
  double get height => isSeparator ? 20 : 40;
}
