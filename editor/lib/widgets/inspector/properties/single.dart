import 'package:flutter/material.dart';
import 'package:core/core.dart';

import 'text_field.dart';

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
            propertyKey: propertyKey,
          ),
        ),
      ],
    );
  }
}
