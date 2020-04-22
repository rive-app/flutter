import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

class IntValueConverter extends InputValueConverter<int> {
  @override
  int fromEditingValue(String value) => int.tryParse(value) ?? 0;

  @override
  String toEditingValue(int value) => value.toString();

  @override
  int drag(int value, double amount) => (value - amount).round();

  static final IntValueConverter instance = IntValueConverter();
}
