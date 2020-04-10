import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable red color channel value.
class RedValueConverter extends InputValueConverter<HSVColor> {
  final Color color;

  RedValueConverter(HSVColor hsv) : color = hsv.toColor();

  @override
  HSVColor fromEditingValue(String value) => HSVColor.fromColor(
        Color.fromARGB(
          color.alpha,
          int.parse(value).clamp(0, 255).toInt(),
          color.green,
          color.blue,
        ),
      );

  @override
  String toEditingValue(HSVColor value) => value.toColor().red.toString();

  @override
  HSVColor drag(HSVColor value, double amount) => HSVColor.fromColor(
        Color.fromARGB(
          color.alpha,
          (value.toColor().red - amount).clamp(0, 255).toInt(),
          color.green,
          color.blue,
        ),
      );
}
