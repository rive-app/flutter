import 'package:flutter/material.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/animation/animation_panel_contents.dart';
import 'package:rive_editor/widgets/common/animated_factor_builder.dart';
import 'package:rive_editor/widgets/common/fractional_intrinsic_height.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

/// Shell for the animation panel that allows it to slide up from the bottom
/// when animation mode is activated. See [AnimationPanelContents] for the
/// various component widgets that actually make up the panel.
class AnimationPanel extends StatefulWidget {
  @override
  _AnimationPanelState createState() => _AnimationPanelState();
}

class _AnimationPanelState extends State<AnimationPanel>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    var activeFile = ActiveFile.of(context);
    return ValueListenableBuilder(
      valueListenable: activeFile.mode,
      child: AnimationPanelContents(),
      builder: (context, EditorMode mode, child) {
        return AnimatedFactorBuilder(
          child: child,
          factor: mode == EditorMode.animate ? 1 : 0,
          builder: (context, factor, child) => FractionalIntrinsicHeight(
            heightFactor: factor,
            // Don't add the animation panel contents (or the animations
            // managers) to the layout if we're not showing the panel at all,
            // save some cycles.
            child: factor != 0
                ? ResizePanel(
                    drawOffset: -2,
                    hitSize: 10,
                    direction: ResizeDirection.vertical,
                    side: ResizeSide.start,
                    min: 50,
                    max: 600,
                    defaultSize: 300,
                    child: child,
                  )
                : const SizedBox(),
          ),
        );
      },
    );
  }
}
