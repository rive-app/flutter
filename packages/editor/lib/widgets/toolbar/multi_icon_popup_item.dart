import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Custom PopupContextItem that automatically wires itself up to change
/// it's icon depending on a notifier value. Also automatically wires up the
/// tool icon and selection states.
class MultiIconPopupItem extends PopupContextItem {
  MultiIconPopupItem(
    String name, {
    @required String Function() iconSelector,
    ShortcutAction shortcut,
    List<PopupContextItem> popup,
    ValueNotifier notifier,
    Function() select,
  }) : super(
          name,
          iconBuilder: (context, isHovered) => TintedIcon(
            icon: iconSelector(),
            color: isHovered
                ? RiveTheme.of(context).colors.buttonHover
                : RiveTheme.of(context).colors.buttonNoHover,
          ),
          rebuildItem: notifier,
          shortcut: shortcut,
          popup: popup,
          select: select ?? () {},
        );
}
