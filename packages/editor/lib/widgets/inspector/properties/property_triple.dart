import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';

class PropertyTriple<T> extends StatelessWidget {
  final List<Core> objects;
  final int propertyKeyA;
  final int propertyKeyB;
  final int propertyKeyC;
  final String name;
  final InputValueConverter<T> converter;

  const PropertyTriple({
    @required this.objects,
    @required this.propertyKeyA,
    @required this.propertyKeyB,
    @required this.propertyKeyC,
    @required this.converter,
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
            child: CoreTextField(
              objects: objects,
              propertyKey: propertyKeyA,
              converter: converter,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: CoreTextField(
              objects: objects,
              propertyKey: propertyKeyB,
              converter: converter,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: CoreTextField(
              objects: objects,
              propertyKey: propertyKeyC,
              converter: converter,
            ),
          ),
        ],
      ),
    );
  }
}
