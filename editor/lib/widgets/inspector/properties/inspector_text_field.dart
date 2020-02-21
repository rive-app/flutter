import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/multi_core_property_builder.dart';

/// A text field that lives within the inspector.
/// 
/// The [propertyKey] is used to extract the associated field data to be 
/// displayed within this text field.
class InspectorTextField extends StatelessWidget {
  final List<Core> objects;
  final int propertyKey;

  const InspectorTextField({
    @required this.objects,
    @required this.propertyKey,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiCorePropertyBuilder(
      objects: objects,
      propertyKey: propertyKey,
      builder: (context, double value, _) => TextField(
        controller: TextEditingController(text: value?.toString() ?? '-'),
        onSubmitted: (stringValue) {
          var value = double.parse(stringValue);
          if (objects.isEmpty) {
            return;
          }
          for (final object in objects) {
            object.context.setObjectProperty(object, propertyKey, value);
          }
          // TODO: Help me obi-wan
          objects.first.context.captureJournalEntry();
        },
      ),
    );
  }
}
