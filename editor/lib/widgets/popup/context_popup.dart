import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

import 'list_popup.dart';

typedef PopupItemWidgetBuilder = Widget Function(BuildContext, bool);
typedef ColorBuilder = Color Function(bool);

class PopupContextItem<T> extends PopupListItem<T> {
  /// When provided this will be called to build a widget to be displayed at the
  /// start of the row, use this for custom (or changing) icons in the popup
  /// item. For example, the Avatar in the hamburger menu.
  final PopupItemWidgetBuilder iconBuilder;

  /// Provide the string name that matches a file in the images/icons folder
  /// without the extension. So assets/images/icons/tool-create.png would just
  /// be 'tool-create'.
  final String icon;

  /// Icon color which works as an override. If you want to only override the
  /// color in certain conditions, use the [iconColorBuilder].
  final Color iconColor;

  /// Builder called when the widget rebuilds to return the appropriate color to
  /// use. Is passed whether or not the row is hovered.
  final ColorBuilder iconColorBuilder;

  /// Text label to show in the row for this popup item.
  final String name;

  /// When provided the item will display the key combination to trigger the
  /// shortcut.
  final ShortcutAction shortcut;

  /// TODO: implement this. Builder to build a special control widget (like the
  /// TextField for the file name in the hamburger menu). Currenlty not
  /// implemented!
  final WidgetBuilder widgetBuilder;

  @override
  final ChangeNotifier rebuildItem;

  @override
  final List<PopupContextItem<T>> popup;

  @override
  final SelectCallback<T> select;

  PopupContextItem(
    this.name, {
    this.icon,
    this.iconColor,
    this.iconBuilder,
    this.shortcut,
    this.widgetBuilder,
    this.popup,
    this.select,
    this.rebuildItem,
    this.iconColorBuilder,
  });

  @override
  String toString() {
    return name ?? super.toString();
  }

  PopupContextItem.separator()
      : iconBuilder = null,
        icon = null,
        iconColor = null,
        iconColorBuilder = null,
        name = null,
        shortcut = null,
        widgetBuilder = null,
        popup = null,
        select = null,
        rebuildItem = null;

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
        if (iconBuilder != null) iconBuilder.call(context, isHovered),
        if (iconBuilder != null) const SizedBox(width: 10),
        if (icon != null)
          TintedIcon(
            color: iconColorBuilder?.call(isHovered) ??
                iconColor ??
                (isHovered
                    ? Colors.white
                    : const Color.fromRGBO(
                        112,
                        112,
                        112,
                        1,
                      )),
            icon: icon,
          ),
        if (icon != null) const SizedBox(width: 10),
        Text(
          name,
          style: TextStyle(
            fontFamily: 'Roboto-Regular',
            fontSize: 13,
            color: isHovered ? Colors.white : const Color(0xFF8C8C8C),
          ),
        ),
        Expanded(child: Container()),
        if (shortcut != null)
          Text(
            ShortcutBindings.of(context)
                    ?.lookupKeysLabel(shortcut)
                    ?.toUpperCase() ??
                "",
            style: const TextStyle(
              fontFamily: 'Roboto-Regular',
              fontSize: 13,
              color: Color(0xFF666666),
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

  static bool hasIcon<T>(String icon, List<PopupContextItem<T>> list) {
    for (final item in list) {
      if (item.icon == icon) {
        return true;
      }
      if (item.popup != null) {
        if (hasIcon(icon, item.popup)) {
          return true;
        }
      }
    }
    return false;
  }
}
