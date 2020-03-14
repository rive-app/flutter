import 'dart:math';

import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for translation values (x and y).
class TranslationValueConverter extends InputValueConverter<double> {
  static const int displayDecimalPlaces = 2;
  static const int editDecimalPlaces = 4;
  static final double _editDecimalDivider =
      pow(10, editDecimalPlaces).toDouble();
  static final double _displayDecimalDivider =
      pow(10, displayDecimalPlaces).toDouble();

  @override
  double fromEditingValue(String value) => double.parse(value);

  @override
  String toDisplayValue(double value) =>
      ((value * _displayDecimalDivider).roundToDouble() /
              _displayDecimalDivider)
          .toString();
  @override
  String toEditingValue(double value) =>
      ((value * _editDecimalDivider).roundToDouble() / _editDecimalDivider)
          .toString();

  static final TranslationValueConverter instance = TranslationValueConverter();
}
