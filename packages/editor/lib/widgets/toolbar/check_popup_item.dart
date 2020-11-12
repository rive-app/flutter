import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Custom PopupContextItem that automatically wires itself up to respond to
/// selected state changes in the stage. Also automatically wires up the tool
/// icon and selection states.
class CheckPopupItem extends PopupContextItem {
  CheckPopupItem(
    String name, {
    ShortcutAction shortcut,
    ChangeNotifier notifier,
    Function() select,
    bool Function() isChecked,
    bool dismissOnSelect = true,
  }) : super(
          name,
          iconBuilder: (context, isHovered) => isChecked()
              ? TintedIcon(
                  icon: PackedIcon.popupCheck,
                  color: isHovered
                      ? RiveTheme.of(context).colors.buttonHover
                      : RiveTheme.of(context).colors.buttonNoHover,
                )
              : const SizedBox(width: 20),
          padIcon: !isChecked(),
          rebuildItem: notifier,
          shortcut: shortcut,
          select: select,
          dismissOnSelect: dismissOnSelect,
        );
}
