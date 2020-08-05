import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:vector_math/vector_math.dart';

/// Value converter for translation values (x and y).
class RotationValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter displayFormatter = DoubleFormatter(0);
  static final DoubleFormatter editFormatter = DoubleFormatter(3);

  @override
  double fromEditingValue(String value) {
    final parsedValue = double.tryParse(value);
    return parsedValue == null ? null : radians(parsedValue);
  }

  @override
  String toDisplayValue(double value) =>
      displayFormatter.format(degrees(value)) + '°';

  @override
  String toEditingValue(double value) => editFormatter.format(degrees(value));

  static final RotationValueConverter instance = RotationValueConverter();

  @override
  double drag(double value, double amount) => value - radians(amount);
}
