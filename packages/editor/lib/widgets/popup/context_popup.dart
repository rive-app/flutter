import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

import 'list_popup.dart';

typedef PopupItemWidgetBuilder = Widget Function(BuildContext, bool);
typedef ColorBuilder = Color Function(bool);

class PopupContextItem extends PopupListItem {
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

  /// Special widget (like the TextField for the file name in the hamburger
  /// menu).
  @override
  final Widget child;

  /// When set to true this will add padding when no icons option is selected.
  final bool padIcon;

  @override
  final ChangeNotifier rebuildItem;

  @override
  final List<PopupContextItem> popup;

  @override
  final SelectCallback select;

  @override
  final bool dismissOnSelect;

  PopupContextItem(this.name,
      {this.icon,
      this.iconColor,
      this.iconBuilder,
      this.shortcut,
      this.child,
      this.popup,
      this.select,
      this.rebuildItem,
      this.iconColorBuilder,
      this.padIcon = false,
      this.dismissOnSelect = true});

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
        child = null,
        popup = null,
        select = null,
        rebuildItem = null,
        padIcon = null,
        dismissOnSelect = true;

  bool get isSeparator => name == null;

  Widget itemBuilder(BuildContext context, bool isHovered) {
    if (isSeparator) {
      // The edgeinset is there to push the horizontal line onto
      // the full pixel line (rather than spanning two pixels at half opacity)
      return Center(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
        child: Container(
          height: 1,
          color: RiveTheme.of(context).colors.separator,
        ),
      ));
    }
    final children = <Widget>[const SizedBox(width: 20)];

    if (iconBuilder != null) {
      children.addAll(
          [iconBuilder.call(context, isHovered), const SizedBox(width: 10)]);
    } else if (icon != null) {
      children.addAll([
        TintedIcon(
          color: iconColorBuilder?.call(isHovered) ??
              iconColor ??
              (isHovered
                  ? RiveTheme.of(context).colors.buttonHover
                  : RiveTheme.of(context).colors.buttonNoHover),
          icon: icon,
        ),
        const SizedBox(width: 10)
      ]);
    }
    // create other stuff
    else if (padIcon) {
      children.addAll([const SizedBox(width: 30)]);
    }
    // pad icon space
    children.addAll([
      Text(
        name,
        style: isHovered
            ? RiveTheme.of(context).textStyles.popupHovered
            : RiveTheme.of(context).textStyles.popupText,
      ),
      const Spacer(),
      if (shortcut != null)
        Text(
          ShortcutBindings.of(context)
                  ?.lookupKeysLabel(shortcut)
                  ?.toUpperCase() ??
              "",
          style: RiveTheme.of(context).textStyles.popupShortcutText,
        ),
      if (child != null) ...[
        child,
      ],
      if (popup != null && popup.isNotEmpty)
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            isHovered ? Colors.white : const Color.fromRGBO(112, 112, 112, 1),
            BlendMode.srcIn,
          ),
          child: const Image(
            image: AssetImage('assets/images/icons/chevron.png'),
          ),
        ),
      const SizedBox(width: 20),
    ]);
    return Row(
      children: children,
    );
  }

  @override
  bool get canSelect => !isSeparator;

  @override
  double get height => isSeparator ? 20 : 40;

  static bool hasIcon(String icon, List<PopupContextItem> list) {
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
