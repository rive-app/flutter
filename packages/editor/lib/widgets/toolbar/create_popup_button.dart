import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/bone_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/node_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/triangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/vector_pen_tool.dart';
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
      defaultIcon: PackedIcon.toolCreate,
      makeItems: (file) => <PopupContextItem>[
        PopupContextItem(
          'Shape',
          icon: PackedIcon.toolShapes,
          popup: [
            ToolPopupItem(
              'Rectangle',
              icon: RectangleTool.instance.icon,
              listenable: file.stage.toolListenable,
              isSelected: () => file.stage.tool == RectangleTool.instance,
              shortcut: ShortcutAction.rectangleTool,
              select: () => file.stage.tool = RectangleTool.instance,
            ),
            ToolPopupItem(
              'Ellipse',
              icon: EllipseTool.instance.icon,
              listenable: file.stage.toolListenable,
              isSelected: () => file.stage.tool == EllipseTool.instance,
              shortcut: ShortcutAction.ellipseTool,
              select: () => file.stage.tool = EllipseTool.instance,
            ),
            // PopupContextItem(
            //   'Polygon',
            //   icon: 'tool-polygon',
            //   select: () {},
            // ),
            // PopupContextItem(
            //   'Star',
            //   icon: 'tool-star',
            //   select: () {},
            // ),
            ToolPopupItem(
              'Triangle',
              icon: TriangleTool.instance.icon,
              listenable: file.stage.toolListenable,
              isSelected: () => file.stage.tool == TriangleTool.instance,
              select: () => file.stage.tool = TriangleTool.instance,
            ),
          ],
          select: () {},
        ),
        ToolPopupItem(
          'Pen',
          icon: PackedIcon.toolPen,
          listenable: file.stage.toolListenable,
          isSelected: () => file.stage.tool == VectorPenTool.instance,
          shortcut: ShortcutAction.penTool,
          select: () {
            file.stage.tool = VectorPenTool.instance;
          },
        ),
        PopupContextItem.separator(),
        ToolPopupItem(
          'Artboard',
          icon: ArtboardTool.instance.icon,
          listenable: file.stage.toolListenable,
          isSelected: () => file.stage.tool == ArtboardTool.instance,
          shortcut: ShortcutAction.artboardTool,
          select: () => file.stage.tool = ArtboardTool.instance,
        ),
        ToolPopupItem(
          'Bone',
          icon: PackedIcon.toolBone,
          shortcut: ShortcutAction.boneTool,
          isSelected: () => file.stage.tool == BoneTool.instance,
          select: () => file.stage.tool = BoneTool.instance,
        ),
        ToolPopupItem(
          'Node',
          icon: PackedIcon.toolNode,
          listenable: file.stage.toolListenable,
          isSelected: () => file.stage.tool == NodeTool.instance,
          shortcut: ShortcutAction.nodeTool,
          select: () {
            file.stage.tool = NodeTool.instance;
          },
        ),
        // PopupContextItem(
        //   'Solo',
        //   icon: 'tool-solo',
        //   shortcut: ShortcutAction.soloTool,
        //   select: () {},
        // ),
      ],
    );
  }
}
