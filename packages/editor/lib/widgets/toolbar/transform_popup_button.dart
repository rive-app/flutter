import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';

import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
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
      tip: const Tip(label: 'Transform Tools'),
      defaultIcon: PackedIcon.toolAuto,
      makeItems: (file) {
        return <PopupContextItem>[
          ToolPopupItem(
            'Select',
            icon: AutoTool.instance.icon,
            listenable: file.stage.toolListenable,
            isSelected: () => file.stage.tool == AutoTool.instance,
            shortcut: ShortcutAction.autoTool,
            select: () => file.stage.tool = AutoTool.instance,
          ),
          ToolPopupItem(
            'Translate',
            icon: TranslateTool.instance.icon,
            listenable: file.stage.toolListenable,
            isSelected: () => file.stage.tool == TranslateTool.instance,
            shortcut: ShortcutAction.translateTool,
            select: () => file.stage.tool = TranslateTool.instance,
          ),
          PopupContextItem.separator(),
          CheckPopupItem(
            'Freeze',
            notifier: ShortcutAction.freezeToggle,
            isChecked: () => ShortcutAction.freezeToggle.value,
            select: ShortcutAction.freezeToggle.toggle,
            dismissOnSelect: false,
            shortcut: ShortcutAction.freezeToggle,
          ),
          /*
          PopupContextItem(
            'Rotate',
            icon: 'tool-rotate',
            shortcut: ShortcutAction.rotateTool,
            select: () {},
          ),
          PopupContextItem(
            'Scale',
            icon: 'tool-scale',
            shortcut: ShortcutAction.scaleTool,
            select: () {},
          ),
          PopupContextItem(
            'Pose',
            icon: 'tool-pose',
            shortcut: ShortcutAction.poseTool,
            select: () {},
          ),
          PopupContextItem(
            'Origin',
            icon: 'tool-origin',
            select: () {},
          ),
          PopupContextItem.separator(),
          MultiIconPopupItem(
            'Show Axis',
            notifier: file.stage.axisCheckNotifier,
            iconSelector: () {
              switch (file.stage.axisCheck) {
                case AxisCheckState.local:
                  return 'popup-local';
                case AxisCheckState.parent:
                  return 'popup-parent';
                default:
                  return 'popup-world';
              }
            },
            popup: [
              CheckPopupItem(
                'Local',
                notifier: file.stage.axisCheckNotifier,
                isChecked: () => file.stage.axisCheck == AxisCheckState.local,
                select: () => file.stage.axisCheck = AxisCheckState.local,
              ),
              CheckPopupItem(
                'Parent',
                notifier: file.stage.axisCheckNotifier,
                isChecked: () => file.stage.axisCheck == AxisCheckState.parent,
                select: () => file.stage.axisCheck = AxisCheckState.parent,
              ),
              CheckPopupItem(
                'World',
                notifier: file.stage.axisCheckNotifier,
                isChecked: () => file.stage.axisCheck == AxisCheckState.world,
                select: () => file.stage.axisCheck = AxisCheckState.world,
              ),
            ],
          ),
          CheckPopupItem(
            'Freeze Joints',
            notifier: file.stage.freezeJointsNotifier,
            shortcut: ShortcutAction.freezeJointsToggle,
            isChecked: () => file.stage.freezeJoints,
            select: () =>
                file.rive.triggerAction(ShortcutAction.freezeJointsToggle),
            dismissOnSelect: false,
          ),
          CheckPopupItem(
            'Freeze Images',
            notifier: file.stage.freezeImagesNotifier,
            shortcut: ShortcutAction.freezeImagesToggle,
            isChecked: () => file.stage.freezeImages,
            select: () =>
                file.rive.triggerAction(ShortcutAction.freezeImagesToggle),
            dismissOnSelect: false,
          ),
          */
        ];
      },
    );
  }
}
