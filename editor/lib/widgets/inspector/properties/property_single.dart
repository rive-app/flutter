import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

class PropertySingle extends StatelessWidget {
  final List<Core> objects;
  final int propertyKey;
  final String name;

  const PropertySingle({
    @required this.objects,
    @required this.propertyKey,
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
            style: const TextStyle(color:Color(0xFF8C8C8C)),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: InspectorTextField(
              objects: objects,
              propertyKey: propertyKey,
            ),
          ),
        ],
      ),
    );
  }
}
