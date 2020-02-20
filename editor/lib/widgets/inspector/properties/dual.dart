import 'package:flutter/material.dart';
import 'package:core/core.dart';
<<<<<<< HEAD:editor/lib/widgets/inspector/properties/property_dual.dart
import 'package:rive_editor/widgets/multi_core_property_builder.dart';
=======

import 'text_field.dart';
>>>>>>> adding controller base:editor/lib/widgets/inspector/properties/dual.dart

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
