import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/theme.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:flutter/material.dart';

/// Custom PopupContextItem that automatically wires itself up to respond to
/// selected tool changes in the stage. Also automatically wires up the tool
/// icon and selection states.
class ToolPopupItem extends PopupContextItem {
  ToolPopupItem(
    String name, {
    String icon,
    ShortcutAction shortcut,
    ValueNotifier notifier,
    bool Function() isSelected,
    Function() select,
  }) : super(
          name,
          icon: icon,
          rebuildItem: notifier,
          iconColorBuilder: (isHovered) => isSelected()
              ? RiveThemeData().colors.popupIconSelected
              : isHovered
                  ? RiveThemeData().colors.popupIconHover
                  : RiveThemeData().colors.popupIcon,
          shortcut: shortcut,
          select: select,
        );
}
