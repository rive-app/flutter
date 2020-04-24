import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/animation/animation_toolbar.dart';
import 'package:rive_editor/widgets/animation/animations_list.dart';
import 'package:rive_editor/widgets/animation/timeline_viewport_controls.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

import 'linear_animation_tree.dart';

/// The contents that display inside of the animation panel.
class AnimationPanelContents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var animationManager = AnimationsProvider.of(context);
    return ColoredBox(
      color: theme.colors.animationPanelBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 236,
            child: ColoredBox(
              color: theme.colors.tabBackground,
              child: animationManager == null
                  ? const SizedBox()
                  : AnimationsList(
                      animationManager: animationManager,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          ResizePanel(
            hitSize: 10,
            direction: ResizeDirection.horizontal,
            side: ResizeSide.end,
            min: 300,
            max: 600,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                AnimationToolbar(),
                Expanded(
                  child: LinearAnimationTree(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Placeholder for timeline and curve editor.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                TimelineViewportControls(),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                      color: theme.colors.timelineBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 200),
        ],
      ),
    );
  }
}
