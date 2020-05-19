import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

/// Text field for T values. Takes a T listenable into which the text field
/// value will be sent.
class ValueListenableTextField<T> extends StatelessWidget {
  final FocusNode focusNode;
  const ValueListenableTextField({
    @required this.listenable,
    @required this.converter,
    this.change,
    this.completeChange,
    this.focusNode,
    Key key,
  }) : super(key: key);
  final ValueListenable<T> listenable;
  final InputValueConverter<T> converter;
  final void Function(T value) change;
  final void Function(T value) completeChange;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: listenable,
      builder: (context, value, _) => InspectorTextField<T>(
        focusNode: focusNode,
        value: value,
        change: change,
        converter: converter,
        completeChange: completeChange,
      ),
    );
  }
}
