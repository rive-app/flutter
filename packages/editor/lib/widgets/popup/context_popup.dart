import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';

import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef PopupItemWidgetBuilder = Widget Function(BuildContext, bool);
typedef ColorBuilder = Color Function(bool);

class PopupContextItem extends PopupListItem {
  /// When provided this will be called to build a widget to be displayed at the
  /// start of the row, use this for custom (or changing) icons in the popup
  /// item. For example, the Avatar in the hamburger menu.
  final PopupItemWidgetBuilder iconBuilder;

  /// Provide the packed icon definition from PackedIcon static icon
  /// definitions.
  final Iterable<PackedIcon> icon;

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
  final Listenable rebuildItem;

  @override
  final List<PopupContextItem> popup;

  @override
  final double popupWidth;

  @override
  final SelectCallback select;

  @override
  final bool dismissOnSelect;

  PopupContextItem(
    this.name, {
    this.icon,
    this.iconColor,
    this.iconBuilder,
    this.shortcut,
    this.child,
    this.popup,
    this.select,
    this.rebuildItem,
    this.iconColorBuilder,
    this.padIcon = false,
    this.dismissOnSelect = true,
    this.popupWidth,
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
        child = null,
        popup = null,
        select = null,
        rebuildItem = null,
        padIcon = null,
        popupWidth = null,
        dismissOnSelect = true;

  /// Make a focusable PopupContexItem that gets a callback with the generated
  /// key and focusNode to build the child. Note the child is built only once.
  factory PopupContextItem.focusable(
    String name, {
    void Function() select,
    Widget Function(FocusNode, Key) child,
  }) {
    final FocusNode focusNode = FocusNode();
    final Key key = GlobalKey();
    return PopupContextItem(
      name,
      dismissOnSelect: false,
      select: () {
        focusNode.requestFocus();
        select?.call();
      },
      child: child(focusNode, key),
    );
  }

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
        TintedIcon(
            color: isHovered
                ? Colors.white
                : const Color.fromRGBO(112, 112, 112, 1),
            icon: PackedIcon.chevron),
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

  /// Find the context item with the specified icon (if one exists).
  static PopupContextItem withIcon(
      Iterable<PackedIcon> icon, List<PopupContextItem> list) {
    for (final item in list) {
      if (item.icon == icon) {
        return item;
      }
      if (item.popup != null) {
        var found = withIcon(icon, item.popup);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }
}
