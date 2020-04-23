import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/animation/animation_toolbar.dart';
import 'package:rive_editor/widgets/animation/animations_list.dart';
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
          // Placeholder for timeline and curve editor.
          const Expanded(
            child: ColoredBox(
              color: Color(0x45000000),
            ),
          ),
          const SizedBox(width: 200),
        ],
      ),
    );
  }
}
