import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
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

class AnimationTimePopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var animationManager = EditingAnimationProvider.of(context);
    if (animationManager == null) {
      return const SizedBox();
    }

    // We want to rebuild the whole thing whenever the fps changes as we need to
    // recomute our converter.
    return CorePropertyBuilder(
      object: animationManager.editingAnimation,
      propertyKey: LinearAnimationBase.fpsPropertyKey,
      builder: (context, int fps, _) {
        var converter = TimeCodeValueConverter(fps);
        var theme = RiveTheme.of(context);

        return RivePopupButton(
          width: 221,
          // Custom icon builder to show the zoom level
          // instead of a menu icon
          iconBuilder: (context, rive, isHovered) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: StreamBuilder<int>(
                stream: animationManager.currentTime,
                builder: (context, snapshot) => snapshot.hasData
                    ? Text(
                        converter.toDisplayValue(snapshot.data),
                        textAlign: TextAlign.right,
                        style: theme.textStyles.basic.copyWith(
                          color: isHovered
                              ? theme.colors.toolbarButtonHover
                              : theme.colors.toolbarButton,
                        ),
                      )
                    : const SizedBox(),
              ),
            );
          },
          contextItemsBuilder: (context) {
            return [
              PopupContextItem.focusable(
                'Current',
                child: (focus, key) => SizedBox(
                  width: 62,
                  child: ValueStreamBuilder<int>(
                    stream: animationManager.currentTime,
                    builder: (context, snapshot) => snapshot.hasData
                        ? InspectorTextField<int>(
                            key: key,
                            focusNode: focus,
                            value: snapshot.data,
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
                    objects: [animationManager.editingAnimation],
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
                    objects: [animationManager.editingAnimation],
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
                      child: CorePropertyBuilder<int>(
                        object: animationManager.editingAnimation,
                        propertyKey: LinearAnimationBase.fpsPropertyKey,
                        builder: (context, fps, _) => InspectorTextField<int>(
                          key: key,
                          focusNode: focus,
                          value: fps,
                          change: (value) {
                            print("CHANGE FPS $value");
                          },
                          converter: IntValueConverter.instance,
                        ),
                      ),
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
              // PopupContextItem.separator(),
              // CheckPopupItem(
              //   'Show All Keys Row',
              //   notifier: file.stage.showAxisNotifier,
              //   isChecked: () => file.stage.showAxis,
              //   select: () => file.stage.showAxis = !file.stage.showAxis,
              //   dismissOnSelect: false,
              // ),
            ];
          },
        );
      },
    );
  }
}
