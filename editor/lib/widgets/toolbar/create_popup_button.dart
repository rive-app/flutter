import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';
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
      makeItems: (rive) => <PopupContextItem<Rive>>[
        PopupContextItem(
          'Shape',
          icon: 'tool-shapes',
          popup: [
            ToolPopupItem(
              'Rectangle',
              rive: rive,
              tool: RectangleTool.instance,
              shortcut: ShortcutAction.rectangleTool,
            ),
            ToolPopupItem(
              'Ellipse',
              rive: rive,
              tool: EllipseTool.instance,
              shortcut: ShortcutAction.ellipseTool,
            ),
            PopupContextItem(
              'Polygon',
              icon: 'tool-polygon',
              select: (Rive rive) {},
            ),
            PopupContextItem(
              'Star',
              icon: 'tool-star',
              select: (Rive rive) {},
            ),
            PopupContextItem(
              'Triangle',
              icon: 'tool-triangle',
              select: (Rive rive) {},
            ),
          ],
          select: (Rive rive) {},
        ),
        PopupContextItem(
          'Pen',
          icon: 'tool-pen',
          shortcut: ShortcutAction.penTool,
          select: (Rive rive) {},
        ),
        PopupContextItem.separator(),
        ToolPopupItem(
          'Artboard',
          rive: rive,
          tool: ArtboardTool.instance,
          shortcut: ShortcutAction.artboardTool,
        ),
        PopupContextItem(
          'Bone',
          icon: 'tool-bone',
          shortcut: ShortcutAction.boneTool,
          select: (Rive rive) {},
        ),
        PopupContextItem(
          'Node',
          icon: 'tool-node',
          shortcut: ShortcutAction.nodeTool,
          select: (Rive rive) {},
        ),
        PopupContextItem(
          'Solo',
          icon: 'tool-solo',
          shortcut: ShortcutAction.soloTool,
          select: (Rive rive) {},
        ),
      ],
    );
  }
}
