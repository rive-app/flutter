import 'dart:ui';

import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Custom PopupContextItem that automatically wires itself up to respond to
/// selected state changes in the stage. Also automatically wires up the tool
/// icon and selection states.
class CheckPopupItem<T> extends PopupContextItem<Rive> {
  CheckPopupItem(
    String name, {
    ShortcutAction shortcut,
    T value,
    ValueNotifier<T> notifier,
  }) : super(
          name,
          iconBuilder: (context, isHovered) => notifier.value == value
              ? TintedIcon(
                  icon: 'popup-check',
                  color: isHovered
                      ? RiveTheme.of(context).colors.buttonHover
                      : RiveTheme.of(context).colors.buttonNoHover,
                )
              : const SizedBox(width: 20),
          padIcon: notifier.value != value,
          rebuildItem: notifier,
          shortcut: shortcut,
          select: (rive) => notifier.value = value,
        );
}
