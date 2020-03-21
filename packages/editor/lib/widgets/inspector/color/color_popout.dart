import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/color_slider.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:rive_editor/widgets/inspector/color/gradient_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/hue_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/opacity_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/saturation_brightness_picker.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// The contents of the color picker shown in a popout.
class ColorPopout extends StatelessWidget {
  final InspectingColor inspecting;

  const ColorPopout({
    Key key,
    this.inspecting,
  }) : super(key: key);

  Widget _stopEditor(ColorType type, Widget combo, RiveThemeData theme) {
    if (type == ColorType.solid) {
      return combo;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        combo,
        Separator(
          padding: const EdgeInsets.only(
            bottom: 20,
          ),
          color: theme.colors.inspectorSeparator,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ValueListenableBuilder(
            valueListenable: inspecting.stops,
            builder: (context, List<InspectingColorStop> stops, child) =>
                ValueListenableBuilder(
              valueListenable: inspecting.editingIndex,
              builder: (context, int editingIndex, child) => MultiColorSlider(
                color: stops[editingIndex].color,
                activeIndex: editingIndex,
                values:
                    stops.map((stop) => stop.position).toList(growable: false),
                hitTrack: inspecting.addStop,
                changeValue: inspecting.changeStopPosition,
                changeIndex: inspecting.changeStopIndex,
                completeChange: inspecting.completeChange,
                background: (context) => Container(
                  child: CustomPaint(
                    painter: GradientSliderBackground(stops),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        ValueListenableBuilder(
          valueListenable: inspecting.type,
          builder: (context, ColorType type, child) => _stopEditor(
            type,
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              child: ComboBox<ColorType>(
                sizing: ComboSizing.content,
                options: ColorType.values,
                value: type,
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
                change: inspecting.changeType,
              ),
            ),
            theme,
          ),
        ),
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
