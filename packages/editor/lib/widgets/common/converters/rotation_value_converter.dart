import 'dart:math';

import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for translation values (x and y).
class RotationValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter displayFormatter = DoubleFormatter(2);
  static final DoubleFormatter editFormatter = DoubleFormatter(3);

  @override
  double fromEditingValue(String value) => double.parse(value) / 180 * pi;

  @override
  String toDisplayValue(double value) =>
      displayFormatter.format(value / pi * 180) + '°';

  @override
  String toEditingValue(double value) => editFormatter.format(value / pi * 180);

  static final RotationValueConverter instance = RotationValueConverter();
}
