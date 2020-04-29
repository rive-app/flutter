import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/animation/animation_editor.dart';
import 'package:rive_editor/widgets/animation/animations_list.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// The contents that display inside of the animation panel.
class AnimationPanelContents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return ColoredBox(
      color: theme.colors.animationPanelBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 236,
            child: ColoredBox(
              color: theme.colors.tabBackground,
              child: const AnimationsList(),
            ),
          ),
          Expanded(
            child: AnimationEditor(),
          ),
        ],
      ),
    );
  }
}
