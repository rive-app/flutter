import 'package:flutter/material.dart';
import 'package:core/core.dart';

import '../../multi_core_property_builder.dart';

class PropertyDual extends StatelessWidget {
  final List<Core> objects;
  final int propertyKeyA;
  final int propertyKeyB;
  final String name;

  const PropertyDual({
    @required this.objects,
    @required this.propertyKeyA,
    @required this.propertyKeyB,
    this.name,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(name, style: const TextStyle(color: Colors.white)),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: InspectorTextField(
            objects: objects,
            propertyKey: propertyKeyA,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: InspectorTextField(
            objects: objects,
            propertyKey: propertyKeyB,
          ),
        ),
      ],
    );
  }
}

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
