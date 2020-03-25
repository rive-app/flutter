import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class PropertyColor<T> extends StatelessWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final String name;
  final InputValueConverter<T> converter;

  const PropertyColor({
    @required this.objects,
    @required this.propertyKey,
    this.converter,
    this.name,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var textStyles = theme.textStyles;
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 7,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              name,
              style: textStyles.inspectorPropertyLabel,
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            flex: 1,
            child: InspectorColorSwatch(),
          ),
          const SizedBox(width: 20),
          Flexible(flex: 1, child: Container()),
        ],
      ),
    );
  }
}
