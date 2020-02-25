import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

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
    return Container(
      padding: const EdgeInsets.only(left: 20.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            name,
            style: const TextStyle(color: Color(0xFF8C8C8C)),
          ),
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
      ),
    );
  }
}
