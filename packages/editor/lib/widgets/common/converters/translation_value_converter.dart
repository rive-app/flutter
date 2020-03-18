import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for translation values (x and y).
class TranslationValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter displayFormatter = DoubleFormatter(2);
  static final DoubleFormatter editFormatter = DoubleFormatter(4);

  @override
  double fromEditingValue(String value) => double.parse(value);

  @override
  String toDisplayValue(double value) => displayFormatter.format(value);

  @override
  String toEditingValue(double value) => editFormatter.format(value);

  static final TranslationValueConverter instance = TranslationValueConverter();

  @override
  double drag(double value, double amount) => value - amount;
}
