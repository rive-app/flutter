import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/converters/alpha_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/blue_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/brightness_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/green_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/hex_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/hue_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/red_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/saturation_value_converter.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/color_slider.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:rive_editor/widgets/inspector/color/gradient_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/hue_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/opacity_slider_background.dart';
import 'package:rive_editor/widgets/inspector/color/saturation_brightness_picker.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
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
    if (type == ColorType.solid || type == null) {
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
    return ValueListenableBuilder(
      valueListenable: inspecting.type,
      builder: (context, ColorType type, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (inspecting.canChangeType) ...[
            const SizedBox(height: 20),
            _stopEditor(
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
          ],
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
                    change: type == null ? null : inspecting.changeColor,
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
                              changeValue: type == null
                                  ? null
                                  : (value) {
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
                              changeValue: type == null
                                  ? null
                                  : (value) {
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
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _ColorTriplet(
                  value: hsv,
                  labelA: 'H',
                  labelB: 'S',
                  labelC: 'B',
                  converterA: HueValueConverter(hsv),
                  converterB: SaturationValueConverter(hsv),
                  converterC: BrightnessValueConverter(hsv),
                  change: type == null ? null : inspecting.changeColor,
                  completeChange: inspecting.completeChange,
                ),
                const SizedBox(height: 15),
                _ColorTriplet(
                  value: hsv,
                  labelA: 'R',
                  labelB: 'G',
                  labelC: 'B',
                  converterA: RedValueConverter(hsv),
                  converterB: GreenValueConverter(hsv),
                  converterC: BlueValueConverter(hsv),
                  change: type == null ? null : inspecting.changeColor,
                  completeChange: inspecting.completeChange,
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _LabeledTextField(
                          label: 'HEX',
                          value: hsv,
                          padRight: true,
                          converter: HexValueConverter.instance,
                          change: type == null ? null : inspecting.changeColor,
                          completeChange: inspecting.completeChange,
                        ),
                      ),
                      Expanded(
                        child: _LabeledTextField(
                          value: hsv,
                          label: 'A',
                          converter: AlphaValueConverter(hsv),
                          change: type == null ? null : inspecting.changeColor,
                          completeChange: inspecting.completeChange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorTriplet extends StatelessWidget {
  final HSVColor value;
  final String labelA, labelB, labelC;
  final InputValueConverter<HSVColor> converterA, converterB, converterC;
  final void Function(HSVColor value) change;
  final void Function() completeChange;

  const _ColorTriplet({
    Key key,
    this.labelA,
    this.labelB,
    this.labelC,
    this.converterA,
    this.converterB,
    this.converterC,
    this.value,
    this.change,
    this.completeChange,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _LabeledTextField(
              label: labelA,
              converter: converterA,
              value: value,
              padRight: true,
              change: change,
              completeChange: completeChange,
            ),
          ),
          Expanded(
            child: _LabeledTextField(
              label: labelB,
              converter: converterB,
              value: value,
              padRight: true,
              change: change,
              completeChange: completeChange,
            ),
          ),
          Expanded(
            child: _LabeledTextField(
              label: labelC,
              converter: converterC,
              value: value,
              change: change,
              completeChange: completeChange,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final bool padRight;
  final InputValueConverter<HSVColor> converter;
  final HSVColor value;
  final void Function(HSVColor value) change;
  final void Function() completeChange;

  const _LabeledTextField({
    Key key,
    this.label,
    this.padRight = false,
    this.converter,
    this.value,
    this.change,
    this.completeChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var labelStyle = RiveTheme.of(context).textStyles.inspectorPropertyLabel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 4,
            right: 5,
          ),
          child: Text(
            label,
            style: labelStyle,
          ),
        ),
        Expanded(
          child: InspectorTextField(
            value: value,
            converter: converter,
            change: change,
            completeChange: completeChange,
          ),
        ),
        if (padRight) const SizedBox(width: 5),
      ],
    );
  }
}
