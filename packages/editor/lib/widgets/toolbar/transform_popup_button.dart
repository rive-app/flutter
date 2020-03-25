import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';

import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/tip.dart';

import 'package:rive_editor/widgets/toolbar/check_popup_item.dart';
import 'package:rive_editor/widgets/toolbar/multi_icon_popup_item.dart';
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
      defaultIcon: 'tool-auto',
      makeItems: (rive) {
        return <PopupContextItem>[
          PopupContextItem(
            'Select',
            icon: 'tool-auto',
            shortcut: ShortcutAction.autoTool,
            select: () {},
          ),
          ToolPopupItem(
            'Translate',
            icon: TranslateTool.instance.icon,
            notifier: rive.stage.value.toolNotifier,
            isSelected: () => rive.stage.value.tool == TranslateTool.instance,
            shortcut: ShortcutAction.translateTool,
            select: () => rive.triggerAction(ShortcutAction.translateTool),
          ),
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
            notifier: rive.stage.value.axisCheckNotifier,
            iconSelector: () {
              switch (rive.stage.value.axisCheck) {
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
                notifier: rive.stage.value.axisCheckNotifier,
                isChecked: () =>
                    rive.stage.value.axisCheck == AxisCheckState.local,
                select: () => rive.stage.value.axisCheck = AxisCheckState.local,
              ),
              CheckPopupItem(
                'Parent',
                notifier: rive.stage.value.axisCheckNotifier,
                isChecked: () =>
                    rive.stage.value.axisCheck == AxisCheckState.parent,
                select: () =>
                    rive.stage.value.axisCheck = AxisCheckState.parent,
              ),
              CheckPopupItem(
                'World',
                notifier: rive.stage.value.axisCheckNotifier,
                isChecked: () =>
                    rive.stage.value.axisCheck == AxisCheckState.world,
                select: () => rive.stage.value.axisCheck = AxisCheckState.world,
              ),
            ],
          ),
          CheckPopupItem(
            'Freeze Joints',
            notifier: rive.stage.value.freezeJointsNotifier,
            shortcut: ShortcutAction.freezeJointsToggle,
            isChecked: () => rive.stage.value.freezeJoints,
            select: () => rive.triggerAction(ShortcutAction.freezeJointsToggle),
            dismissOnSelect: false,
          ),
          CheckPopupItem(
            'Freeze Images',
            notifier: rive.stage.value.freezeImagesNotifier,
            shortcut: ShortcutAction.freezeImagesToggle,
            isChecked: () => rive.stage.value.freezeImages,
            select: () => rive.triggerAction(ShortcutAction.freezeImagesToggle),
            dismissOnSelect: false,
          ),
        ];
      },
    );
  }
}
