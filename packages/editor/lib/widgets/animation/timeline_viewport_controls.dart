import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/editing_animation_manager.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class TimelineViewportControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var editingAnimation = EditingAnimationProvider.of(context);

    return ValueListenableBuilder(
      valueListenable: editingAnimation.viewport,
      builder: (context, TimelineViewport viewport, _) {
        return const SizedBox();
      },
    );
  }
}
