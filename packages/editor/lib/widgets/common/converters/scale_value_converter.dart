import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for scale values (x and y).
class ScaleValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter displayFormatter = DoubleFormatter(2);
  static final DoubleFormatter editFormatter = DoubleFormatter(4);

  @override
  double fromEditingValue(String value) => double.parse(value);

  @override
  String toDisplayValue(double value) => displayFormatter.format(value);

  @override
  String toEditingValue(double value) => editFormatter.format(value);

  static final ScaleValueConverter instance = ScaleValueConverter();

  @override
  double drag(double value, double amount) => value - amount;
}
