import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/int_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/speed_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/timecode_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';

/// Debounce duration for updating the display time when an animation is playing
const debounceDuration = Duration(milliseconds: 33);

/// Popup button showing time options for the animation.
class AnimationTimePopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ActiveFile.of(context).editingAnimationManager,
      builder: (context, EditingAnimationManager animationManager, _) {
        if (animationManager == null) {
          return const SizedBox();
        }

        final theme = RiveTheme.of(context);

        /// Build the popup menu content
        List<PopupContextItem> _buildPopupList(
                InputValueConverter<int> converter) =>
            [
              PopupContextItem.focusable(
                'Current',
                child: (focus, key) => SizedBox(
                  width: 62,
                  child: ValueStreamBuilder<double>(
                    stream: animationManager.currentTime,
                    builder: (context, snapshot) => snapshot.hasData
                        ? InspectorTextField<int>(
                            key: key,
                            focusNode: focus,
                            value: snapshot.data.round(),
                            change: (value) {},
                            converter: converter,
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
              PopupContextItem.focusable(
                'Duration',
                child: (focus, key) => SizedBox(
                  width: 62,
                  child: CoreTextField<int>(
                    focusNode: focus,
                    key: key,
                    objects: [animationManager.animation],
                    propertyKey: LinearAnimationBase.durationPropertyKey,
                    converter: converter,
                  ),
                ),
              ),
              PopupContextItem.focusable(
                'Playback Speed',
                child: (focus, key) => SizedBox(
                  width: 62,
                  child: CoreTextField<double>(
                    key: key,
                    focusNode: focus,
                    objects: [animationManager.animation],
                    propertyKey: LinearAnimationBase.speedPropertyKey,
                    converter: SpeedValueConverter.instance,
                  ),
                ),
              ),
              PopupContextItem.focusable(
                'Snap Keys',
                child: (focus, key) => Row(
                  children: [
                    SizedBox(
                      width: 37,
                      child: ValueStreamBuilder<int>(
                          stream: animationManager.fps,
                          builder: (context, snapshot) => snapshot.hasData
                              ? InspectorTextField<int>(
                                  key: key,
                                  focusNode: focus,
                                  value: snapshot.data,

                                  /// Manager will handle this for us after it's
                                  /// done processing the change.
                                  captureJournalEntry: false,
                                  change: (value) {
                                    animationManager.previewRateChange
                                        .add(value);
                                  },
                                  completeChange: (value) {
                                    animationManager.changeRate.add(value);
                                  },
                                  converter: IntValueConverter.instance,
                                )
                              : const SizedBox()),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'fps',
                      textAlign: TextAlign.right,
                      style: theme.textStyles.inspectorPropertyLabel,
                    ),
                  ],
                ),
              ),
            ];

        // We want to rebuild the whole thing whenever the
        // fps changes as we need to recomute our converter.
        return CorePropertyBuilder(
          object: animationManager.animation,
          propertyKey: LinearAnimationBase.fpsPropertyKey,
          // This will rebuild only when the fps is changed
          builder: (context, int fps, _) {
            final converter = TimeCodeValueConverter(fps);

            return RivePopupButton(
              hoverColor:
                  RiveTheme.of(context).colors.timelineButtonBackGroundHover,
              width: 221,
              // Custom icon builder to show the zoom level
              // instead of a menu icon
              iconBuilder: (context, rive, isHovered) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: ValueStreamBuilder<double>(
                      stream: animationManager.currentTime,
                      // This will rebuild whenever the time changes
                      builder: (context, snapshot) {
                        return snapshot.hasData
                            ? Text(
                                converter.toDisplayValue(snapshot.data.round()),
                                style: theme.textStyles.basic.copyWith(
                                  color: isHovered
                                      ? theme.colors.toolbarButtonHover
                                      : theme.colors.toolbarButton,
                                ),
                              )
                            : const SizedBox();
                      }),
                );
              },
              contextItemsBuilder: (context) => _buildPopupList(converter),
            );
          },
        );
      },
    );
  }
}
