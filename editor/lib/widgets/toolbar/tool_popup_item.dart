import 'dart:ui';

import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
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
              ? const Color(0xFF57A5E0)
              : isHovered ? Colors.white : const Color(0xFF707070),
          shortcut: shortcut,
          select: select,
        );
}
