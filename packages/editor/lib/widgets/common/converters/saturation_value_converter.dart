import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable saturation value.
class SaturationValueConverter extends InputValueConverter<HSVColor> {
  final HSVColor color;
  static final DoubleFormatter editFormatter = DoubleFormatter(2);

  SaturationValueConverter(this.color);

  @override
  HSVColor fromEditingValue(String value) => HSVColor.fromAHSV(
        color.alpha,
        color.hue,
        double.parse(value) / 100,
        color.value,
      );

  @override
  String toDisplayValue(HSVColor value) =>
      '${(value.saturation * 100).round()}%';

  @override
  String toEditingValue(HSVColor value) =>
      editFormatter.format(value.saturation * 100);

  @override
  HSVColor drag(HSVColor value, double amount) => HSVColor.fromAHSV(
        color.alpha,
        color.hue,
        (value.saturation - amount/100).clamp(0,1).toDouble(),
        color.value,
      );
}
