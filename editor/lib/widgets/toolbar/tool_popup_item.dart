import 'dart:ui';

import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:flutter/material.dart';

/// Custom PopupContextItem that automatically wires itself up to respond to
/// selected tool changes in the stage. Also automatically wires up the tool
/// icon and selection states.
class ToolPopupItem extends PopupContextItem<Rive> {
  ToolPopupItem(
    String name, {
    ShortcutAction shortcut,
    Rive rive,
    StageTool tool,
  }) : super(name,
            icon: tool.icon,
            rebuildItem: rive.stage.value.toolNotifier,
            iconColorBuilder: (isHovered) => rive.stage.value.tool == tool
                ? const Color(0xFF57A5E0)
                : isHovered ? Colors.white : const Color(0xFF707070),
            shortcut: shortcut,
            select: (rive) {
              rive.stage.value.tool = tool;
            });
}
