import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/draw_order_tree_controller.dart';
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/common/draw_order_key_button.dart';
import 'package:rive_editor/widgets/draw_order.dart';
import 'package:rive_editor/widgets/hierarchy.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

/// Left hand panel contains the hierarchy and draw order widgets
class HierarchyPanel extends StatefulWidget {
  @override
  _HierarchyPanelState createState() => _HierarchyPanelState();
}

class _HierarchyPanelState extends State<HierarchyPanel> {
  bool hierarchySelected = true;
  bool hierarchyHovered = false;
  bool drawOrderHovered = false;

  @override
  Widget build(BuildContext context) {
    final file = ActiveFile.of(context);
    var theme = RiveTheme.of(context);
    return ResizePanel(
      hitSize: theme.dimensions.resizeEdgeSize,
      direction: ResizeDirection.horizontal,
      side: ResizeSide.end,
      min: 300,
      max: 500,
      child: Container(
        color: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 17),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => hierarchyHovered = true),
                    onExit: (_) => setState(() => hierarchyHovered = false),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => hierarchySelected = true);
                      },
                      child: Text('HIERARCHY',
                          style: hierarchySelected
                              ? theme.textStyles.hierarchyTabActive
                              : hierarchyHovered
                                  ? theme.textStyles.hierarchyTabHovered
                                  : theme.textStyles.hierarchyTabInactive),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18, top: 17),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => drawOrderHovered = true),
                    onExit: (_) => setState(() => drawOrderHovered = false),
                    child: GestureDetector(
                      onTap: () => setState(() => hierarchySelected = false),
                      child: ValueListenableBuilder(
                        valueListenable:
                            ActiveFile.of(context).editingAnimationManager,
                        builder:
                            (context, EditingAnimationManager manager, _) =>
                                Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DRAW ORDER',
                                style: hierarchySelected
                                    ? drawOrderHovered
                                        ? theme.textStyles.hierarchyTabHovered
                                        : theme.textStyles.hierarchyTabInactive
                                    : theme.textStyles.hierarchyTabActive),
                            // only show keystate if we're animating...

                            if (manager != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 5, top: 2),
                                child: DrawOrderKeyButton(manager: manager),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hierarchySelected)
              Expanded(
                child: ValueListenableBuilder<HierarchyTreeController>(
                  valueListenable: file.treeController,
                  builder: (context, controller, _) =>
                      HierarchyTreeView(controller: controller),
                ),
              ),
            if (!hierarchySelected)
              Expanded(
                // child: DrawOrder(),
                child: ValueListenableBuilder<DrawOrderTreeController>(
                  valueListenable: file.drawOrderTreeController,
                  builder: (context, controller, _) =>
                      DrawOrderTreeView(controller: controller),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
