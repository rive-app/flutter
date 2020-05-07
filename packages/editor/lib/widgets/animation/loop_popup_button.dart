import 'dart:math';

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
          case Loop.pingPong:
            icon = 'ping-pong';
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
              'Loop',
              icon: 'loop',
              select: () {
                animation.loop = Loop.loop;
                animation.context.captureJournalEntry();
              },
            ),
            PopupContextItem(
              'Ping Pong',
              icon: 'ping-pong',
              select: () {
                animation.loop = Loop.pingPong;
                animation.context.captureJournalEntry();
              },
            ),
            PopupContextItem.separator(),
            PopupContextItem(
              'Work Area',
              // notifier: file.stage.showRulersNotifier,
              iconBuilder: (context, isHovered) => CorePropertyBuilder(
                object: animation,
                propertyKey: LinearAnimationBase.enableWorkAreaPropertyKey,
                builder: (context, bool isEnabled, _) => isEnabled
                    ? TintedIcon(
                        icon: 'popup-check',
                        color: isHovered
                            ? RiveTheme.of(context).colors.buttonHover
                            : RiveTheme.of(context).colors.buttonNoHover,
                      )
                    : const SizedBox(width: 20),
              ),
              padIcon: !animation.enableWorkArea,
              select: () => animation.toggleWorkArea(),
              dismissOnSelect: false,
            ),
          ],
        );
      },
    );
  }
}


/// Helper to toggle work area on the linear animation.
extension ToggleWorkArea on LinearAnimation {
  void toggleWorkArea() {
    enableWorkArea = !enableWorkArea;
    if (enableWorkArea) {
      // when we're enabling, do some validation
      if (workStart == null) {
        workStart = 0;
        workEnd = duration;
      } else {
        workStart = max(0, workStart);
        workEnd = min(duration, workEnd);
      }
    }
    context.captureJournalEntry();
  }
}