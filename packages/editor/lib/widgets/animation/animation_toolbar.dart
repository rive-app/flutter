import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/animation/animation_time_popup_button.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';

/// Toolbar shown across the top of the animation panel's hierarchy.
class AnimationToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 9,
      ),
      child: Row(
        children: [
          TintedIconButton(
            icon: 'play',
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            onPress: () {
              print('play');
            },
          ),
          TintedIconButton(
            icon: 'to-start',
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            onPress: () {
              print('to-start');
            },
          ),
          TintedIconButton(
            icon: 'loop',
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            onPress: () {
              print('loop');
            },
          ),
          const Expanded(
            child: SizedBox(),
          ),
          AnimationTimePopupButton(),
        ],
      ),
    );
  }
}
