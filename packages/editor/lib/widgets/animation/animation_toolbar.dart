import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/animation/animation_time_popup_button.dart';
import 'package:rive_editor/widgets/animation/loop_popup_button.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// Toolbar shown across the top of the animation panel's hierarchy.
class AnimationToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          _PlaybackButton(),
          TintedIconButton(
            backgroundHover:
                RiveTheme.of(context).colors.timelineButtonBackGroundHover,
            icon: 'to-start',
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            onPress: () {
              var animationManager = EditingAnimationProvider.find(context);
              animationManager.changeCurrentTime.add(0);
            },
          ),
          LoopPopupButton(),
          const Spacer(),
          AnimationTimePopupButton(),
          // AnimationTimePopupButton(),
        ],
      ),
    );
  }
}

class _PlaybackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var animationManager = EditingAnimationProvider.of(context);
    if (animationManager == null) {
      return const SizedBox();
    }

    return ValueStreamBuilder<bool>(
      stream: animationManager.isPlaying,
      builder: (context, snapshot) => TintedIconButton(
        backgroundHover:
            RiveTheme.of(context).colors.timelineButtonBackGroundHover,
        icon: snapshot.hasData && snapshot.data ? 'pause' : 'play',
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        onPress: () {
          animationManager.changePlayback
              .add(snapshot.hasData && !snapshot.data);
        },
      ),
    );
  }
}
