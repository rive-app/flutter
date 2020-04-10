import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for percentage values (0-X represented as %).
class PercentageInputConverter extends InputValueConverter<double> {
  final DoubleFormatter editFormatter;

  PercentageInputConverter(int significantDigits)
      : editFormatter = DoubleFormatter(significantDigits);
  @override
  double fromEditingValue(String value) => double.parse(value) / 100;

  @override
  String toDisplayValue(double value) => '${(value * 100).round()}%';

  @override
  String toEditingValue(double value) => editFormatter.format(value * 100);

  static final PercentageInputConverter instance = PercentageInputConverter(2);

  @override
  double drag(double value, double amount) => (value ?? 1) - amount / 100;
}
