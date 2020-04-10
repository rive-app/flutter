import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable blue color channel value.
class BlueValueConverter extends InputValueConverter<HSVColor> {
  final Color color;

  BlueValueConverter(HSVColor hsv) : color = hsv.toColor();

  @override
  HSVColor fromEditingValue(String value) => HSVColor.fromColor(
        Color.fromARGB(
          color.alpha,
          color.red,
          color.green,
          int.parse(value).clamp(0, 255).toInt(),
        ),
      );

  @override
  String toEditingValue(HSVColor value) => value.toColor().blue.toString();

  @override
  HSVColor drag(HSVColor value, double amount) => HSVColor.fromColor(
        Color.fromARGB(
          color.alpha,
          color.red,
          color.green,
          (value.toColor().blue - amount).clamp(0, 255).toInt(),
        ),
      );
}
