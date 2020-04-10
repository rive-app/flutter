import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable green color channel value.
class GreenValueConverter extends InputValueConverter<HSVColor> {
  final Color color;

  GreenValueConverter(HSVColor hsv) : color = hsv.toColor();

  @override
  HSVColor fromEditingValue(String value) => HSVColor.fromColor(
        Color.fromARGB(
          color.alpha,
          color.red,
          int.parse(value).clamp(0, 255).toInt(),
          color.blue,
        ),
      );

  @override
  String toEditingValue(HSVColor value) => value.toColor().green.toString();

  @override
  HSVColor drag(HSVColor value, double amount) => HSVColor.fromColor(
        Color.fromARGB(
          color.alpha,
          color.red,
          (value.toColor().green - amount).clamp(0, 255).toInt(),
          color.blue,
        ),
      );
}
