import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for zoom values (0-X represented as %).
class ZoomInputConverter extends InputValueConverter<double> {
  static final DoubleFormatter editFormatter = DoubleFormatter(2);

  @override
  double fromEditingValue(String value) => double.parse(value)/100;

  @override
  String toDisplayValue(double value) => '${(value * 100).round()}%';

  @override
  String toEditingValue(double value) => editFormatter.format(value*100);

  static final ZoomInputConverter instance = ZoomInputConverter();
}
