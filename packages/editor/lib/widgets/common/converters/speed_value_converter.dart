import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

class SpeedValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter displayFormatter = DoubleFormatter(2);
  static final DoubleFormatter editFormatter = DoubleFormatter(4);

  @override
  double fromEditingValue(String value) => double.parse(value);

  @override
  String toDisplayValue(double value) => '${displayFormatter.format(value)}x';

  @override
  String toEditingValue(double value) => editFormatter.format(value);

  static final SpeedValueConverter instance = SpeedValueConverter();

  @override
  double drag(double value, double amount) => value - amount/10;
}
