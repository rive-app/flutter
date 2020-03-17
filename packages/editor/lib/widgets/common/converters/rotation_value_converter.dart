import 'dart:math';

import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:vector_math/vector_math.dart';

/// Value converter for translation values (x and y).
class RotationValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter displayFormatter = DoubleFormatter(2);
  static final DoubleFormatter editFormatter = DoubleFormatter(3);

  @override
  double fromEditingValue(String value) => radians(double.parse(value));

  @override
  String toDisplayValue(double value) =>
      displayFormatter.format(degrees(value)) + '°';

  @override
  String toEditingValue(double value) => editFormatter.format(value / pi * 180);

  static final RotationValueConverter instance = RotationValueConverter();
}
