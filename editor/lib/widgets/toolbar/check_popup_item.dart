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
class CheckPopupItem extends PopupContextItem<Rive> {
  CheckPopupItem(
    String name, {
    ShortcutAction shortcut,
    Rive rive,
    AxisCheckState axisCheck,
  }) : super(
          name,
          iconBuilder: (context, isHovered) =>
              rive.stage.value.axisCheck == axisCheck
                  ? TintedIcon(
                      icon: 'popup-check',
                      color: isHovered
                          ? RiveTheme.of(context).colors.buttonHover
                          : RiveTheme.of(context).colors.buttonNoHover,
                    )
                  : const SizedBox(width: 20),
          padIcon: rive.stage.value.axisCheck != axisCheck,
          rebuildItem: rive.stage.value.axisCheckNotifier,
          shortcut: shortcut,
          select: (rive) => rive.stage.value.axisCheck = axisCheck,
        );
}
