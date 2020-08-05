import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable hue value.
class HueValueConverter extends InputValueConverter<HSVColor> {
  final HSVColor color;

  static final DoubleFormatter displayFormatter = DoubleFormatter(0);
  static final DoubleFormatter editFormatter = DoubleFormatter(2);

  HueValueConverter(this.color);

  @override
  HSVColor fromEditingValue(String value) {
    final parsedValue = double.tryParse(value);
    return parsedValue == null
        ? null
        : HSVColor.fromAHSV(
            color.alpha,
            parsedValue.clamp(0, 360).toDouble(),
            color.saturation,
            color.value,
          );
  }

  @override
  String toDisplayValue(HSVColor value) => displayFormatter.format(value.hue);

  @override
  String toEditingValue(HSVColor value) => editFormatter.format(value.hue);

  @override
  HSVColor drag(HSVColor value, double amount) => HSVColor.fromAHSV(
        color.alpha,
        (value.hue - amount).clamp(0, 360).toDouble(),
        color.saturation,
        color.value,
      );
}
