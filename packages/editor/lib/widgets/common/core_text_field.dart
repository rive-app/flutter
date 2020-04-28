import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

/// A text field that manipulates core properties.
///
/// The [propertyKey] is hander over to [CorePropertiesBuilder] to extract the
/// associated field data to be displayed within this text field.
class CoreTextField<T> extends StatefulWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final InputValueConverter<T> converter;
  final void Function(T value) change;
  final FocusNode focusNode;

  /// Color for the underline when it's not focused.
  final Color underlineColor;

  /// Color for the underline when this textfield has focus.
  final Color focusedUnderlineColor;

  const CoreTextField({
    @required this.objects,
    @required this.propertyKey,
    this.converter,
    this.change,
    this.focusNode,
    this.underlineColor,
    this.focusedUnderlineColor,
    Key key,
  }) : super(key: key);

  @override
  _CoreTextFieldState<T> createState() => _CoreTextFieldState<T>();
}

class _CoreTextFieldState<T> extends State<CoreTextField<T>> {
  @override
  Widget build(BuildContext context) {
    return CorePropertiesBuilder(
      objects: widget.objects,
      propertyKey: widget.propertyKey,
      builder: (context, T value, _) => InspectorTextField(
        value: value,
        focusNode: widget.focusNode,
        converter: widget.converter,
        underlineColor: widget.underlineColor,
        focusedUnderlineColor: widget.focusedUnderlineColor,
        change: (T value) {
          for (final object in widget.objects) {
            object.context.setObjectProperty(object, widget.propertyKey, value);
          }
          widget.change?.call(value);
        },
      ),
    );
  }
}
