import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Popup button showing loop options for the animation.
class LoopPopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var animationManager = EditingAnimationProvider.of(context);
    if (animationManager == null) {
      return const SizedBox();
    }

    var animation = animationManager.animation;
    // We want to rebuild the whole thing whenever the loop value changes.
    return CorePropertyBuilder(
      object: animation,
      propertyKey: LinearAnimationBase.loopValuePropertyKey,
      builder: (context, int loopValue, _) {
        var loop = animation.loop;
        String icon;
        switch (loop) {
          case Loop.oneShot:
            icon = 'one-shot';
            break;
          case Loop.loop:
            icon = 'loop';
            break;
          case Loop.stopLastKey:
            icon = 'stop-last';
            break;
          case Loop.loopLastKey:
            icon = 'loop-last';
            break;
        }
        final themeColors = RiveTheme.of(context).colors;
        return RivePopupButton(
          iconBuilder: (context, rive, isHovered) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: TintedIcon(
                icon: icon,
                color: isHovered
                    ? themeColors.toolbarButtonHover
                    : themeColors.toolbarButton,
              ),
            );
          },
          contextItemsBuilder: (context) => [
            PopupContextItem(
              'One Shot',
              icon: 'one-shot',
              select: () {
                animation.loop = Loop.oneShot;
                animation.context.captureJournalEntry();
              },
            ),
            PopupContextItem(
              'Stop Last Key',
              icon: 'stop-last',
              select: () {
                animation.loop = Loop.stopLastKey;
                animation.context.captureJournalEntry();
              },
            ),
            PopupContextItem(
              'Loop Last Key',
              icon: 'loop-last',
              select: () {
                animation.loop = Loop.loopLastKey;
                animation.context.captureJournalEntry();
              },
            ),
            PopupContextItem(
              'Loop',
              icon: 'loop',
              select: () {
                animation.loop = Loop.loop;
                animation.context.captureJournalEntry();
              },
            ),
          ],
        );
      },
    );
  }
}
