import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable alpha color channel value.
class AlphaValueConverter extends InputValueConverter<HSVColor> {
  final Color color;

  AlphaValueConverter(HSVColor hsv) : color = hsv.toColor();

  @override
  HSVColor fromEditingValue(String value) {
    final parsedValue = double.tryParse(value);
    return parsedValue == null
        ? null
        : HSVColor.fromColor(
            Color.fromARGB(
              (parsedValue / 100 * 255).clamp(0, 255).toInt(),
              color.red,
              color.green,
              color.blue,
            ),
          );
  }

  @override
  String toEditingValue(HSVColor value) =>
      '${(value.toColor().alpha / 255 * 100).round()}%';

  @override
  HSVColor drag(HSVColor value, double amount) => HSVColor.fromColor(
        Color.fromARGB(
          ((value.toColor().alpha / 255 * 100 - amount) / 100 * 255)
              .clamp(0, 255)
              .toInt(),
          color.red,
          color.green,
          color.blue,
        ),
      );
}
