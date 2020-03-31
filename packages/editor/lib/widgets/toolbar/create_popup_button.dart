import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/node_tool.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/triangle_tool.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/toolbar/tool_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/tool_popup_item.dart';

/// The popup button showed in the toolbar allowing the user to select a create
/// tool. Use [ToolPopupItem] in the items list if you want it to be
/// automatically wired up to the appropriate icon and selection.
class CreatePopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ToolPopupButton(
      tip: const Tip(label: 'Create Tools'),
      defaultIcon: 'tool-create',
      makeItems: (file) => <PopupContextItem>[
        PopupContextItem(
          'Shape',
          icon: 'tool-shapes',
          popup: [
            ToolPopupItem(
              'Rectangle',
              icon: RectangleTool.instance.icon,
              notifier: file.stage.toolNotifier,
              isSelected: () => file.stage.tool == RectangleTool.instance,
              shortcut: ShortcutAction.rectangleTool,
              select: () =>
                  file.rive.triggerAction(ShortcutAction.rectangleTool),
            ),
            ToolPopupItem(
              'Ellipse',
              icon: EllipseTool.instance.icon,
              notifier: file.stage.toolNotifier,
              isSelected: () => file.stage.tool == EllipseTool.instance,
              shortcut: ShortcutAction.ellipseTool,
              select: () => file.rive.triggerAction(ShortcutAction.ellipseTool),
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
            ToolPopupItem(
              'Triangle',
              icon: TriangleTool.instance.icon,
              notifier: file.stage.toolNotifier,
              isSelected: () => file.stage.tool == TriangleTool.instance,
              select: () => file.stage.tool = TriangleTool.instance,
            ),
          ],
          select: () {},
        ),
        ToolPopupItem(
          'Pen',
          icon: 'tool-pen',
          notifier: file.stage.toolNotifier,
          isSelected: () => file.stage.tool == PenTool.instance,
          shortcut: ShortcutAction.penTool,
          select: () {
            file.stage.tool = PenTool.instance;
          },
        ),
        PopupContextItem.separator(),
        ToolPopupItem(
          'Artboard',
          icon: ArtboardTool.instance.icon,
          notifier: file.stage.toolNotifier,
          isSelected: () => file.stage.tool == ArtboardTool.instance,
          shortcut: ShortcutAction.artboardTool,
          select: () => file.rive.triggerAction(ShortcutAction.artboardTool),
        ),
        PopupContextItem(
          'Bone',
          icon: 'tool-bone',
          shortcut: ShortcutAction.boneTool,
          select: () {},
        ),
        ToolPopupItem(
          'Node',
          icon: 'tool-node',
          notifier: file.stage.toolNotifier,
          isSelected: () => file.stage.tool == NodeTool.instance,
          shortcut: ShortcutAction.nodeTool,
          select: () {
            file.stage.tool = NodeTool.instance;
          },
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
