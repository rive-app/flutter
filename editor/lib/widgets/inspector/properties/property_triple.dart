import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

class PropertyTriple extends StatelessWidget {
  final List<Core> objects;
  final int propertyKeyA;
  final int propertyKeyB;
  final int propertyKeyC;
  final String name;

  const PropertyTriple({
    @required this.objects,
    @required this.propertyKeyA,
    @required this.propertyKeyB,
    @required this.propertyKeyC,
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
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: InspectorTextField(
            objects: objects,
            propertyKey: propertyKeyC,
          ),
        ),
      ],
    );
  }
}
