import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
// import 'package:rive_editor/widgets/inherited_widgets.dart';
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
              child: InspectorTextField(
                objects: objects,
                propertyKey: propertyKey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
