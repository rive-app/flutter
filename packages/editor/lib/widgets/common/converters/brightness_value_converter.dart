import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable brightness value.
class BrightnessValueConverter extends InputValueConverter<HSVColor> {
  final HSVColor color;
  static final DoubleFormatter editFormatter = DoubleFormatter(2);

  BrightnessValueConverter(this.color);

  @override
  HSVColor fromEditingValue(String value) => HSVColor.fromAHSV(
        color.alpha,
        color.hue,
        color.saturation,
        double.parse(value) / 100,
      );

  @override
  String toDisplayValue(HSVColor value) => '${(value.value * 100).round()}%';

  @override
  String toEditingValue(HSVColor value) =>
      editFormatter.format(value.value * 100);

  @override
  HSVColor drag(HSVColor value, double amount) => HSVColor.fromAHSV(
        color.alpha,
        color.hue,
        value.saturation,
        (value.value - amount / 100).clamp(0, 1).toDouble(),
      );
}
