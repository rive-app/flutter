import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/color_slider.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:rive_editor/widgets/inspector/color/hue_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/opacity_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/saturation_brightness_picker.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class ColorPopout extends StatelessWidget {
  final InspectingColor inspecting;

  const ColorPopout({
    Key key,
    this.inspecting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ComboBox<ColorType>(
                sizing: ComboSizing.content,
                options: ColorType.values,
                value: ColorType.values[0],
                toLabel: (colorType) {
                  switch (colorType) {
                    case ColorType.solid:
                      return 'Solid';
                    case ColorType.linear:
                      return 'Linear';
                    case ColorType.radial:
                      return 'Radial';
                  }
                  return '';
                },
                chooseOption: (ColorType type) {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder(
          valueListenable: inspecting.editingColor,
          builder: (context, HSVColor hsv, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 153,
                child: SaturationBrightnessPicker(
                  hsv: hsv,
                  change: inspecting.changeColor,
                  complete: inspecting.completeChange,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(
                  20,
                ),
                child: Row(
                  children: [
                    TintedIcon(
                      icon: 'eyedropper',
                      color: theme.colors.popupIcon,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ColorSlider(
                            color:
                                HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                            value: hsv.hue / 360,
                            changeValue: (value) {
                              inspecting.changeColor(
                                HSVColor.fromAHSV(
                                  hsv.alpha,
                                  value * 360,
                                  hsv.saturation,
                                  hsv.value,
                                ),
                              );
                            },
                            completeChange: inspecting.completeChange,
                            background: (context) => Container(
                              child: const CustomPaint(
                                painter: HueSliderBackground(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ColorSlider(
                            color: hsv.toColor(),
                            value: hsv.alpha,
                            changeValue: (value) {
                              inspecting.changeColor(
                                HSVColor.fromAHSV(
                                  value,
                                  hsv.hue,
                                  hsv.saturation,
                                  hsv.value,
                                ),
                              );
                            },
                            completeChange: inspecting.completeChange,
                            background: (context) => Container(
                              child: CustomPaint(
                                painter: OpacitySliderBackground(
                                  color: HSVColor.fromAHSV(
                                    1,
                                    hsv.hue,
                                    hsv.saturation,
                                    hsv.value,
                                  ).toColor(),
                                  background:
                                      RiveTheme.of(context).colors.popupIcon,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
