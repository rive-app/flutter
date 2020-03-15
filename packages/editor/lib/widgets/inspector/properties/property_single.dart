import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class PropertySingle<T> extends StatelessWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final String name;
  final InputValueConverter<T> converter;

  const PropertySingle({
    @required this.objects,
    @required this.propertyKey,
    this.converter,
    this.name,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      padding: const EdgeInsets.only(left: 20, right: 20),
      height: 35,
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: Container(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      name,
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            flex: 2,
            child: Container(
              child: CoreTextField<T>(
                objects: objects,
                propertyKey: propertyKey,
                converter: converter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
