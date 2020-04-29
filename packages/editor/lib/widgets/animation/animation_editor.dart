import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/animation/playhead.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/animation/animation_toolbar.dart';

import 'package:rive_editor/widgets/animation/keyed_object_hierarchy.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/animation/timeline_keys.dart';
import 'package:rive_editor/widgets/animation/timeline_ticks.dart';
import 'package:rive_editor/widgets/animation/timeline_viewport_controls.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

/// Helper to pass animation manager to the editing animation panel which
/// contains the tree with animated properties and timeline with keys.
class AnimationEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var animationManager = EditingAnimationProvider.of(context);
    if (animationManager == null) {
      return const SizedBox();
    }
    return _StatefulEditingAnimation(
      animationManager: animationManager,
    );
  }
}

class _StatefulEditingAnimation extends StatefulWidget {
  final EditingAnimationManager animationManager;

  const _StatefulEditingAnimation({
    @required this.animationManager,
    Key key,
  }) : super(key: key);

  @override
  __StatefulEditingAnimationState createState() =>
      __StatefulEditingAnimationState();
}

class __StatefulEditingAnimationState extends State<_StatefulEditingAnimation> {
  final ScrollController timelineVerticalScroll = ScrollController();
  KeyedObjectTreeController _treeController;
  @override
  void initState() {
    _treeController = KeyedObjectTreeController(widget.animationManager);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _treeController.dispose();
  }

  @override
  void didUpdateWidget(_StatefulEditingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationManager != widget.animationManager) {
      _treeController = KeyedObjectTreeController(widget.animationManager);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResizePanel(
          hitSize: 10,
          direction: ResizeDirection.horizontal,
          side: ResizeSide.end,
          min: 300,
          max: 600,
          deadStart: 48,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              AnimationToolbar(),
              Expanded(
                child: KeyedObjectHierarchy(
                  scrollController: timelineVerticalScroll,
                  treeController: _treeController,
                ),
              ),
            ],
          ),
        ),
        // Placeholder for timeline and curve editor.
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                // The viewport controls, ticks, and timeline+keys are a great
                // candidate for RepaintBoundary as they all change when the
                // viewport changes. We also want to optimize for playback, edit
                // operations need to be high performance but during playback
                // keys aren't being changed, the viewport's not moving, and the
                // ticks don't change.

                // That means that moving a keyframe will result in re-render of
                // the ticks and controls. This can be later optimized with more
                // RepaintBoundaries if we find it's necessary, but I suspect it
                // won't be. The heavier operation during movement of keyframes
                // is just the individual row sorting + merging (and merge
                // sorting) of the all keys.
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      TimelineViewportControls(),
                      const SizedBox(height: 10),
                      TimelineTicks(),
                      Expanded(
                        child: TimelineKeys(
                          theme: theme,
                          verticalScroll: timelineVerticalScroll,
                          treeController: _treeController,
                          animationManager: widget.animationManager,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Stack the playhead on top, this does move during playback so
              // let's make it a super lightweight render op by separating it
              // from the rest of the complex ui.
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                bottom: 0,
                child: Playhead(
                  theme: theme,
                ),
              )
            ],
          ),
        ),
        const SizedBox(width: 200),
      ],
    );
  }
}
