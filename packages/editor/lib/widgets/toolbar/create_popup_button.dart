import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/node_tool.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/triangle_tool.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/tooltip_button.dart';
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
              select: () => rive.triggerAction(ShortcutAction.rectangleTool),
            ),
            ToolPopupItem(
              'Ellipse',
              icon: EllipseTool.instance.icon,
              notifier: rive.stage.value.toolNotifier,
              isSelected: () => rive.stage.value.tool == EllipseTool.instance,
              shortcut: ShortcutAction.ellipseTool,
              select: () => rive.triggerAction(ShortcutAction.ellipseTool),
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
              notifier: rive.stage.value.toolNotifier,
              isSelected: () => rive.stage.value.tool == TriangleTool.instance,
              select: () => rive.stage.value.tool = TriangleTool.instance,
            ),
          ],
          select: () {},
        ),
        ToolPopupItem(
          'Pen',
          icon: 'tool-pen',
          notifier: rive.stage.value.toolNotifier,
          isSelected: () => rive.stage.value.tool == PenTool.instance,
          shortcut: ShortcutAction.penTool,
          select: () {
            rive.stage.value.tool = PenTool.instance;
          },
        ),
        PopupContextItem.separator(),
        ToolPopupItem(
          'Artboard',
          icon: ArtboardTool.instance.icon,
          notifier: rive.stage.value.toolNotifier,
          isSelected: () => rive.stage.value.tool == ArtboardTool.instance,
          shortcut: ShortcutAction.artboardTool,
          select: () => rive.triggerAction(ShortcutAction.artboardTool),
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
          notifier: rive.stage.value.toolNotifier,
          isSelected: () => rive.stage.value.tool == NodeTool.instance,
          shortcut: ShortcutAction.nodeTool,
          select: () {
            rive.stage.value.tool = NodeTool.instance;
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
