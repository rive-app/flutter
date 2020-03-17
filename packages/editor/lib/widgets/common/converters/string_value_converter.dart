import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// A no-op value converter.
class StringValueConverter extends InputValueConverter<String> {
  @override
  String fromEditingValue(String value) => value;

  @override
  String toDisplayValue(String value) => value;

  @override
  String toEditingValue(String value) => value;

  static final StringValueConverter instance = StringValueConverter();

  @override
  bool get allowDrag => false;
}
