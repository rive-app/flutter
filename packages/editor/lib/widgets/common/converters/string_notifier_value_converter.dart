import 'package:flutter/foundation.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

class StringNotifierValueConverter
    extends InputValueConverter<ValueNotifier<String>> {
  StringNotifierValueConverter(this.notifier);
  final ValueNotifier<String> notifier;

  @override
  ValueNotifier<String> fromEditingValue(String value) {
    notifier.value = value;
    return notifier;
  }

  @override
  String toDisplayValue(ValueNotifier<String> value) => value.value;

  @override
  String toEditingValue(ValueNotifier<String> value) => value.value;

  @override
  bool get allowDrag => false;
}
