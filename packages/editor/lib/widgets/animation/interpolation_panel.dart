import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

class InterpolationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var manager = KeyFrameManagerProvider.of(context);
    if (manager == null) {
      return _buildPanel(context, KeyFrameInterpolation.linear, false);
    }

    return ValueStreamBuilder<HashSet<KeyFrame>>(
      stream: manager.selection,
      builder: (context, selection) =>
          ValueStreamBuilder<KeyFrameInterpolation>(
        stream: manager.interpolationType,
        builder: (context, interpolation) => _buildPanel(
          context,
          interpolation.data,
          selection.data.isNotEmpty,
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, KeyFrameInterpolation interpolation,
      bool hasSelection) {
    var theme = RiveTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Interpolation",
                  style: theme.textStyles.inspectorPropertyLabel,
                ),
              ),
              ComboBox(
                  underlineColor: theme.colors.interpolationUnderline,
                  disabled: !hasSelection,
                  sizing: ComboSizing.content,
                  options: KeyFrameInterpolation.values
                      .where((value) => value != KeyFrameInterpolation.cubic)
                      .toList(growable: false),
                  value: interpolation,
                  change: (KeyFrameInterpolation interpolation) {
                    var manager = KeyFrameManagerProvider.find(context);
                    manager.changeInterpolation.add(interpolation);
                  },
                  toLabel: (KeyFrameInterpolation interpolation) =>
                      interpolation == null
                          ? ''
                          : UIStrings.find(context)
                                  .withKey(describeEnum(interpolation)) ??
                              "???"),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: theme.colors.interpolationCurveBackground,
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          )
        ],
      ),
    );
  }
}
