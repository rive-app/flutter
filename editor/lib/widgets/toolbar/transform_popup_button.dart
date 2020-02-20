import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/toolbar/check_popup_item.dart';
import 'package:rive_editor/widgets/toolbar/tool_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/tool_popup_item.dart';

/// The popup button showed in the toolbar allowing the user to select a
/// transform tool. Use [ToolPopupItem] in the items list if you want it to be
/// automatically wired up to the appropriate icon and selection.
class TransformPopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ToolPopupButton(
      defaultIcon: 'tool-auto',
      makeItems: (rive) => <PopupContextItem<Rive>>[
        PopupContextItem(
          'Select',
          icon: 'tool-auto',
          shortcut: ShortcutAction.autoTool,
          select: (Rive rive) {},
        ),
        ToolPopupItem(
          'Translate',
          rive: rive,
          tool: TranslateTool.instance,
          shortcut: ShortcutAction.translateTool,
        ),
        PopupContextItem(
          'Rotate',
          icon: 'tool-rotate',
          shortcut: ShortcutAction.rotateTool,
          select: (Rive rive) {},
        ),
        PopupContextItem(
          'Scale',
          icon: 'tool-scale',
          shortcut: ShortcutAction.scaleTool,
          select: (Rive rive) {},
        ),
        PopupContextItem(
          'Pose',
          icon: 'tool-pose',
          shortcut: ShortcutAction.poseTool,
          select: (Rive rive) {},
        ),
        PopupContextItem(
          'Origin',
          icon: 'tool-origin',
          select: (Rive rive) {},
        ),
        PopupContextItem.separator(),
        PopupContextItem('Show Axis',
            popup: [
              CheckPopupItem(
                'Local',
                rive: rive,
                axisCheck: AxisCheckState.local,
              ),
              CheckPopupItem(
                'Parent',
                rive: rive,
                axisCheck: AxisCheckState.parent,
              ),
              CheckPopupItem(
                'World',
                rive: rive,
                axisCheck: AxisCheckState.world,
              ),
            ],
            select: (Rive rive) {},
            padIcon: true),
        PopupContextItem('Freeze Joints',
            select: (Rive rive) {},
            shortcut: ShortcutAction.freezeJointsToggle,
            padIcon: true),
        PopupContextItem('Freeze Images',
            select: (Rive rive) {},
            shortcut: ShortcutAction.freezeImagesToggle,
            padIcon: true),
      ],
    );
  }
}
