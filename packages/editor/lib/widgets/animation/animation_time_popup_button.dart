import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/widgets/common/converters/timecode_value_converter.dart';
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

        return RivePopupButton(
          width: 221,
          // Custom icon builder to show the zoom level
          // instead of a menu icon
          iconBuilder: (context, rive, isHovered) {
            var theme = RiveTheme.of(context);

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
            var currentKey = GlobalKey();

            return [
              PopupContextItem(
                'Current',
                child: SizedBox(
                  width: 62,
                  child: StreamBuilder<int>(
                    stream: animationManager.currentTime,
                    builder: (context, snapshot) => snapshot.hasData
                        ? InspectorTextField<int>(
                            key: currentKey,
                            value: snapshot.data,
                            change: (value) {},
                            converter: converter,
                          )
                        : const SizedBox(),
                  ),
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
