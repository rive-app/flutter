import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/rive_text_form_field.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';

/// A text field in the Inspector panel.
///
/// The [propertyKey] is hander over to [CorePropertiesBuilder] to extract the
/// associated field data to be displayed within this text field.
class InspectorTextField extends StatefulWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final InputValueConverter converter;

  const InspectorTextField({
    @required this.objects,
    @required this.propertyKey,
    this.converter,
    Key key,
  }) : super(key: key);

  @override
  _InspectorTextFieldState createState() => _InspectorTextFieldState();
}

class _InspectorTextFieldState extends State<InspectorTextField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CorePropertiesBuilder(
      objects: widget.objects,
      propertyKey: widget.propertyKey,
      builder: (context, double value, _) => RiveTextFormField(
        focusNode: _focusNode,
        edgeInsets: const EdgeInsets.only(bottom: 3),
        isNumeric: true,
        initialValue: value?.toString() ?? '-',
        hintText: '',
        // controller: TextEditingController(text: ),
        onComplete: (stringValue, isDragging) {
          dynamic value = widget.converter == null
              ? double.parse(stringValue)
              : widget.converter.fromEditingValue(stringValue);
          if (widget.objects.isEmpty) {
            return;
          }
          for (final object in widget.objects) {
            object.context.setObjectProperty(object, widget.propertyKey, value);
          }
          // TODO: Help me obi-wan
          if (!isDragging) {
            widget.objects.first.context.captureJournalEntry();
          }
        },
      ),
    );
  }
}
