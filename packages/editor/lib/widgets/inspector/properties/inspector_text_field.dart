import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/rive_text_form_field.dart';
import 'package:rive_editor/widgets/multi_core_property_builder.dart';

/// A text field in the Inspector panel.
///
/// The [propertyKey] is hander over to [MultiCorePropertyBuilder] to extract
/// the associated field data to be displayed within this text field.
class InspectorTextField extends StatefulWidget {
  final List<Core> objects;
  final int propertyKey;

  const InspectorTextField({
    @required this.objects,
    @required this.propertyKey,
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
    return MultiCorePropertyBuilder(
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
          var value = double.parse(stringValue);
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
