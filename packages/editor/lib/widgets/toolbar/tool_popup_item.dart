import 'package:flutter/foundation.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';

/// Custom PopupContextItem that automatically wires itself up to respond to
/// selected tool changes in the stage. Also automatically wires up the tool
/// icon and selection states.
class ToolPopupItem extends PopupContextItem {
  ToolPopupItem(
    String name, {
    String icon,
    ShortcutAction shortcut,
    ValueListenable listenable,
    bool Function() isSelected,
    Function() select,
  }) : super(
          name,
          icon: icon,
          rebuildItem: listenable,
          iconColorBuilder: (isHovered) => isSelected()
              ? RiveThemeData().colors.popupIconSelected
              : isHovered
                  ? RiveThemeData().colors.popupIconHover
                  : RiveThemeData().colors.popupIcon,
          shortcut: shortcut,
          select: select,
        );
}
