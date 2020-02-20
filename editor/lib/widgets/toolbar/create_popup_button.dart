import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/toolbar/tool_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/tool_popup_item.dart';

/// The popup button showed in the toolbar allowing the user to select a create
/// tool. Use [ToolPopupItem] in the items list if you want it to be
/// automatically wired up to the appropriate icon and selection.
class CreatePopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ToolPopupButton(
      defaultIcon: 'tool-create',
      makeItems: (rive) => <PopupContextItem>[
        PopupContextItem(
          'Shape',
          icon: 'tool-shapes',
          popup: [
            ToolPopupItem(
              'Rectangle',
              icon: RectangleTool.instance.icon,
              notifier: rive.stage.value.toolNotifier,
              isSelected: () => rive.stage.value.tool == RectangleTool.instance,
              shortcut: ShortcutAction.rectangleTool,
              select: () => rive.stage.value.tool = RectangleTool.instance,
            ),
            ToolPopupItem(
              'Ellipse',
              icon: EllipseTool.instance.icon,
              notifier: rive.stage.value.toolNotifier,
              isSelected: () => rive.stage.value.tool == EllipseTool.instance,
              shortcut: ShortcutAction.ellipseTool,
              select: () => rive.stage.value.tool = EllipseTool.instance,
            ),
            PopupContextItem(
              'Polygon',
              icon: 'tool-polygon',
              select: () {},
            ),
            PopupContextItem(
              'Star',
              icon: 'tool-star',
              select: () {},
            ),
            PopupContextItem(
              'Triangle',
              icon: 'tool-triangle',
              select: () {},
            ),
          ],
          select: () {},
        ),
        PopupContextItem(
          'Pen',
          icon: 'tool-pen',
          shortcut: ShortcutAction.penTool,
          select: () {},
        ),
        PopupContextItem.separator(),
        ToolPopupItem(
          'Artboard',
          icon: ArtboardTool.instance.icon,
          notifier: rive.stage.value.toolNotifier,
          isSelected: () => rive.stage.value.tool == ArtboardTool.instance,
          shortcut: ShortcutAction.artboardTool,
          select: () => rive.stage.value.tool = ArtboardTool.instance,
        ),
        PopupContextItem(
          'Bone',
          icon: 'tool-bone',
          shortcut: ShortcutAction.boneTool,
          select: () {},
        ),
        PopupContextItem(
          'Node',
          icon: 'tool-node',
          shortcut: ShortcutAction.nodeTool,
          select: () {},
        ),
        PopupContextItem(
          'Solo',
          icon: 'tool-solo',
          shortcut: ShortcutAction.soloTool,
          select: () {},
        ),
      ],
    );
  }
}
