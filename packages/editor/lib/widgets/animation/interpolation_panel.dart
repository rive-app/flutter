import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/converters/interpolation_value_converter.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

import 'interpolation_preview.dart';

class InterpolationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ActiveFile.of(context).keyFrameManager,
      builder: (context, KeyFrameManager manager, _) {
        if (manager == null) {
          return _buildPanel(
            context,
            const InterpolationViewModel(KeyFrameInterpolation.linear, null),
            HashSet<KeyFrame>(),
            null,
          );
        }

        return ValueStreamBuilder<HashSet<KeyFrame>>(
          stream: manager.selection,
          builder: (context, selection) =>
              ValueStreamBuilder<InterpolationViewModel>(
            stream: manager.commonInterpolation,
            builder: (context, interpolation) => _buildPanel(
              context,
              interpolation.data,
              selection.data,
              manager,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanel(
    BuildContext context,
    InterpolationViewModel interpolation,
    HashSet<KeyFrame> selection,
    KeyFrameManager manager,
  ) {
    final theme = RiveTheme.of(context);
    final hasEditableInterpolation = selection.isNotEmpty &&
        selection.any((keyframe) => keyframe.canInterpolate);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Interpolation',
                  style: theme.textStyles.inspectorPropertyLabel,
                ),
              ),
              ComboBox(
                  underlineColor: theme.colors.interpolationUnderline,
                  disabled: !hasEditableInterpolation,
                  sizing: ComboSizing.content,
                  options: KeyFrameInterpolation.values,
                  value: interpolation.type,
                  change: (KeyFrameInterpolation interpolation) =>
                      manager.changeInterpolation.add(interpolation),
                  toLabel: (KeyFrameInterpolation interpolation) =>
                      interpolation == null
                          ? ''
                          : UIStrings.find(context)
                                  .withKey(describeEnum(interpolation)) ??
                              '???'),
            ],
          ),
          const SizedBox(height: 13),
          ValueListenableBuilder(
            valueListenable: ActiveFile.of(context).editingAnimationManager,
            builder: (context, EditingAnimationManager animationManager, _) =>
                SizedBox(
              height: 160,
              child: Stack(children: [
                Positioned.fill(
                  child: InterpolationPreview(
                    interpolation: interpolation,
                    selection: selection,
                    manager: manager,
                    timeManager: animationManager,
                  ),
                ),
                if (!hasEditableInterpolation)
                  Center(
                    child: Text(
                      UIStrings.find(context).withKey('select_key'),
                      style: theme.textStyles.inspectorPropertyLabel,
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 13),
          if (hasEditableInterpolation)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Points', style: theme.textStyles.inspectorPropertyLabel),
              const SizedBox(width: 6),
              Expanded(
                child: InspectorTextField(
                    value: interpolation,
                    converter: InterpolationValueConverter.instance,
                    underlineColor: theme.colors.interpolationUnderline,
                    change: (InterpolationViewModel _) {},
                    completeChange: (InterpolationViewModel newInterpolation) {
                      switch (newInterpolation.type) {
                        case KeyFrameInterpolation.cubic:
                          final interpolator = newInterpolation.interpolator;
                          if (interpolator is CubicInterpolator) {
                            final cubic = CubicInterpolationViewModel(
                                interpolator.x1,
                                interpolator.y1,
                                interpolator.x2,
                                interpolator.y2);
                            if (interpolation.type !=
                                KeyFrameInterpolation.cubic) {
                              manager.changeInterpolation
                                  .add(newInterpolation.type);
                            }
                            manager.changeCubic.add(cubic);
                          }
                          break;
                        default:
                          manager.changeInterpolation
                              .add(newInterpolation.type);
                          break;
                      }
                    }),
              )
            ])
        ],
      ),
    );
  }
}
