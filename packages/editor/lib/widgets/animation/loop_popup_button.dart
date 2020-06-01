import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/animation/loop.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Popup button showing loop options for the animation.
class LoopPopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ActiveFile.of(context).editingAnimationManager,
      builder: (context, EditingAnimationManager animationManager, _) {
        if (animationManager == null) {
          return const SizedBox();
        }

        var animation = animationManager.animation;
        // We want to rebuild the whole thing whenever the loop value changes.
        return ValueStreamBuilder<Loop>(
          stream: animationManager.loop,
          builder: (context, snapshot) {
            var loop = snapshot.data;
            Iterable<PackedIcon> icon;
            switch (loop) {
              case Loop.oneShot:
                icon = PackedIcon.oneShot;
                break;
              case Loop.loop:
                icon = PackedIcon.loop;
                break;
              case Loop.pingPong:
                icon = PackedIcon.pingPong;
                break;
            }
            final themeColors = RiveTheme.of(context).colors;
            return RivePopupButton(
              hoverColor: themeColors.timelineButtonBackGroundHover,
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
                  icon: PackedIcon.oneShot,
                  select: () {
                    animationManager.changeLoop.add(Loop.oneShot);
                  },
                ),
                PopupContextItem(
                  'Loop',
                  icon: PackedIcon.loop,
                  select: () {
                    animationManager.changeLoop.add(Loop.loop);
                  },
                ),
                PopupContextItem(
                  'Ping Pong',
                  icon: PackedIcon.pingPong,
                  select: () {
                    animationManager.changeLoop.add(Loop.pingPong);
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
                            icon: PackedIcon.popupCheck,
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
