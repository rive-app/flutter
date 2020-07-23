import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for translation values (x and y).
class TranslationValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter _displayFormatter = DoubleFormatter(1);
  static final DoubleFormatter _editFormatter = DoubleFormatter(2);

  DoubleFormatter get displayFormatter => _displayFormatter;
  DoubleFormatter get editFormatter => _editFormatter;

  @override
  double fromEditingValue(String value) => double.parse(value);

  @override
  String toDisplayValue(double value) => displayFormatter.format(value);

  @override
  String toEditingValue(double value) => editFormatter.format(value);

  static final TranslationValueConverter instance = TranslationValueConverter();

  @override
  double drag(double value, double amount) => value - amount;

  @override
  double fromNull() => 0;
}
